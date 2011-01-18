
using concurrent
using inet

**
** Web socket protocol (draft 76) implementation.
** 
const class WsProtocol : Protocol {
  private static const Log log := Log.get("spectre")
  const Duration? receiveTimeout := 10sec
  const Duration? messageTimeout := null
  
  const |WsHandshakeReq->WsProcessor?| processorFunc
  new make(|WsHandshakeReq->WsProcessor?| processorFunc) { this.processorFunc = processorFunc }
  
  override Bool onConnection(HttpReq httpReq) {
    // check if we support this connection
    if (!httpReq.headers.get("Connection", "").equalsIgnoreCase("upgrade") ||
        !httpReq.headers.get("Upgrade", "").equalsIgnoreCase("websocket"))
      return false

    socket := httpReq.socket
    in := socket.in
    out := socket.out
    
    handshakeReq := WsHandshakeReq(httpReq)
    WsProcessor? processor := processorFunc.call(handshakeReq)
    if (processor == null)
      return true // connection has been processed
    WsHandshakeRes handshakeRes := processor.onHandshake(handshakeReq)

    /*  We need to send the 101 response immediately when using Draft 76 with
        a load balancing proxy, such as HAProxy.  In order to protect an
        unsuspecting non-websocket HTTP server, HAProxy will not send the
        8-byte nonce through the connection until the Upgrade: WebSocket
        request has been confirmed by the WebSocket server by a 101 response
        indicating that the server can handle the upgraded protocol.  We
        therefore must send the 101 response immediately, and then wait for
        the nonce to be forwarded to us afterward in order to finish the
        Draft 76 handshake.
    */
    out.writeChars("HTTP/1.1 101 WebSocket Protocol Handshake\r\n")
    out.writeChars("Upgrade: WebSocket\r\n")
       .writeChars("Connection: Upgrade\r\n")
       .writeChars("Sec-WebSocket-Location: " + handshakeRes.location + "\r\n")
       .writeChars("Sec-WebSocket-Origin: " + handshakeRes.origin + "\r\n")
    if (handshakeRes.protocol != null)
       out.writeChars("Sec-WebSocket-Protocol: " + handshakeRes.protocol + "\r\n")
    out.writeChars("\r\n").flush
    
    key3 := httpReq.in.readBufFully(null, 8)
    out.writeBuf(handshakeRes.challenge(key3)).flush

    conn := WsConnImpl(handshakeReq, socket, this)
    try {
      processor.onReady(conn)
      while (true) {
        msg := conn.read
        if (msg == null)
          break
        processor.onMsg(conn, msg)
      }
    } catch(IOErr e) { // IOErrs are just ok
      log.debug("Error in web socket communication", e)      
    } catch(Err e) {
      log.err("Error in WebSocket communication", e)
    }
    conn.closed.val = true
    try processor.onClose(conn); catch(Err e) log.err("Error closing WebSocket", e)
    return true
  }
}

**
** Represents single WebSocket connection with browser.
** 
const mixin WsConn {
  ** Handshake request that connection has started from.
  abstract WsHandshakeReq req()
  
  ** Read next message from socket. This operation blocks until 
  ** there’ll be a message in WebSocket. Returns 'null' if connection
  ** was closed before anything was received.
  abstract Buf? read()
  
  ** Write text message to the WebSocket.
  abstract Void writeStr(Str msg)
  
  ** Finish WebSocket communication. After this method called it’s impossible 
  ** to write or read to/from this connection anymore.
  abstract Void close()
}

internal const class WsConnImpl : WsConn {
  override const WsHandshakeReq req
  
  const Unsafe     socketUnsafe
        TcpSocket  socket() { socketUnsafe.val }
  const AtomicBool reading := AtomicBool(false)
  const AtomicBool closed := AtomicBool(false)
  const WsProtocol protocol
  
  internal new make(WsHandshakeReq req, TcpSocket socket, WsProtocol protocol) {
    this.req = req
    this.socketUnsafe = Unsafe(socket)
    this.protocol = protocol
  }
  
  override Buf? read() {
    if (closed.val) throw CancelledErr("Attemt to read from socket already closed")
    if (!reading.compareAndSet(false, true)) throw Err("Reading already started in another actor")

    try {
      // There’s no timeout when waiting for client’s messages
      socket.options.receiveTimeout = protocol.messageTimeout
      if (socket.in.peek == null)
        return null
  
      // before we start reading message set a receive timeout in case
      // the client fails to send us data in a timely fashion
      socket.options.receiveTimeout = protocol.receiveTimeout
      frame := WsFrame_HIXIE_76.read(socket.in)
      return frame?.data
    } finally {
      reading.val = false
    }
  }
  
  override Void writeStr(Str msg) {
    if (closed.val) throw CancelledErr("Attemt to write to socket already closed")
    WsFrame_HIXIE_76 { data = msg.toBuf }.write(socket.out)
  }
  
  override Void close() {
    if (closed.compareAndSet(false, true))
      try {
        WsFrame_HIXIE_76.close(socket.out)
        socket.close
      } catch {}
  }
}

**
** WebSocket connection processing mixin. 
** 
const mixin WsProcessor {
  ** Should return WebSocket handshake response. May be overriden to choose
  ** protocol or tune smth else in handshake response.
  virtual WsHandshakeRes? onHandshake(WsHandshakeReq req) { WsHandshakeRes(req) }
  
  ** Will be called after connection has been successfully negotiated.
  virtual Void onReady(WsConn conn) {}
  
  ** When message has been received from client.
  virtual Void onMsg(WsConn conn, Buf msg) {}
  
  ** When client has closed connection. It’s invalid to read/send messages from/to 'conn' in this method.
  virtual Void onClose(WsConn conn) {}
}

const class WsHandshakeReq {
  const Str key1
  const Str key2
  const Str? protocols
  const Str host
  const Str origin
  const Uri uri
  const Bool secure := false

  new make(HttpReq req) {
    h := req.headers
    uri = req.uri
    key1 = h["Sec-WebSocket-Key1"]
    key2 = h["Sec-WebSocket-Key2"]
    origin = h["Origin"]
    host = h["Host"]
    protocols = h["Sec-WebSocket-Protocol"]
  }

  new makeTest(|This|? f := null) { f?.call(this) }
}

const class WsHandshakeRes {
  const Str? protocol
  const Str location
  const Str origin
  
  internal const Int part1
  internal const Int part2
  
  new make(WsHandshakeReq req, |This|? f := null) {
    protocol = req.protocols
    origin = req.origin
    location = (origin.startsWith("https") ? "wss" : "ws") + "://" + req.host + req.uri.pathStr
    
    keyNumber1 := keyToNum(req.key1)
    keyNumber2 := keyToNum(req.key2)
    spaces1 := spaces(req.key1)
    spaces2 := spaces(req.key2)
    if (spaces1 == 0 || keyNumber1 % spaces1 != 0)
      throw Err("Incorrect WebSocket key1: $req.key1")    
    if (spaces2 == 0 || keyNumber2 % spaces2 != 0)
      throw Err("Incorrect WebSocket key2: $req.key2")
    part1 = keyNumber1 / spaces1
    part2 = keyNumber2 / spaces2
    
    f?.call(this)
  }
  
  internal Buf challenge(Buf key3) {
    buf := Buf(16) { endian = Endian.big }
    buf.writeI4(part1)
    buf.writeI4(part2)
    buf.writeBuf(key3, 8)
    
    return buf.toDigest("MD5")
  }
  
  internal static Int keyToNum(Str key) {
    digits := key.chars.findAll { it.isDigit }
    return Str.fromChars(digits).toInt
  }
  
  internal static Int spaces(Str key) {
    amount := 0
    key.chars.each { if (it == ' ') ++amount }
    return amount
  }
}

**
** DataFrame that parses and sends data through web socket connection.
** Conforms to draft-hixie-thewebsocketprotocol-76
** 
class WsFrame_HIXIE_76 {
  Buf data

  new make(|This| f) { f.call(this) }
  
  Void write(OutStream out) {
    out.write(0x00).writeBuf(data).write(0xFF).flush
  }

  static Void close(OutStream out) {
    out.write(0xFF).write(0x00).flush
  }
  
  static WsFrame_HIXIE_76? read(InStream in) {
    b := in.read
    if (b != 0x00) {
      if (b == null || (b == 0xFF && in.read == 0x00)) // FIXME setUp readTimeout
        return null
      
      throw IOErr("Protocol error")
    }

    buf := Buf()
    while(true) { 
      b = in.read
      if (b == null)
        throw IOErr("Protocol error")
      if (b == 0xFF)
        break
      buf.write(b)
    }

    return WsFrame_HIXIE_76 { data = buf.seek(0) }
  }
}

**
** DataFrame that parses and sends data through web socket connection.
** To be used when browsers will catch up. 
** Conforms to draft-ietf-hybi-thewebsocketprotocol-03 protocol
**  
class WsFrame_IETF_03 {
  static const Int continuation := 0
  static const Int close := 1
  static const Int ping := 2
  static const Int pong := 3
  static const Int text := 4
  static const Int binary := 5

  const Bool more := false
  const Bool rsv1 := false
  const Bool rsv2 := false
  const Bool rsv3 := false
  const Bool rsv4 := false
  const Int opcode := text
  Buf data
  
  new make(|This| f) { f.call(this) }
  Void write(OutStream out) {
    len := data.size
    
    out.write((more ? 0x80 : 0).or(rsv1 ? 0x40 : 0).or(rsv2 ? 0x20 : 0).or(rsv3 ? 0x10 : 0).or(opcode.and(0x0F)))
    out.write((rsv4 ? 0x80 : 0).or(len <= 125 ? len : (len <= 0xFFFF ? 126 : 127)))
    if (len > 125) {
      if (len <= 0xFFFF)
        out.writeI2(len)
      else
        out.writeI8(len)
    }
    out.writeBuf(data).flush
  }
  
  // TODO support continuation
  new read(InStream in) {
    b1 := in.read
    if (b1 == null)
      throw IOErr("Cannot read data frame")
    more = b1.and(0x80) != 0
    rsv1 = b1.and(0x40) != 0
    rsv2 = b1.and(0x20) != 0
    rsv3 = b1.and(0x10) != 0
    opcode = b1.and(0x0F)
    
    b2 := in.read
    if (b2 == null)
      throw IOErr("Cannot read data frame")
    rsv4 = b2.and(0x80) != 0
    len := b2.and(0x7F)
    if (len == 126) {
      len = in.readU2()
    } else if (len == 127) {
      len = in.readS8()
    }
    
    // TODO support binary
    data = in.readBufFully(null, len)
  }
}
