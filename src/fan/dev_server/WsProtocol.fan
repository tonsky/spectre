using concurrent
using inet::IpAddr

**
** Web socket protocol (draft 76) implementation.
** 
const class WsProtocol : Protocol {
  private static const Log log := Log.get("spectre")
  const Duration? receiveTimeout := 10sec
  const Duration? messageTimeout := null
  
  const |WsHandshakeReq->WsProcessor?| processorFunc
  new make(|WsHandshakeReq->WsProcessor?| processorFunc) { this.processorFunc = processorFunc }
  
  WsConnImpl? _conn { get { Actor.locals["spectre.WsProtocol._conn"] }
                      set { Actor.locals["spectre.WsProtocol._conn"] = it } }
  
  WsProcessor? _processor { get { Actor.locals["spectre.WsProtocol._processor"] }
                            set { Actor.locals["spectre.WsProtocol._processor"] = it } }
  
  override ProtocolRes onFirstConnection(HttpReq httpReq, TcpSocket socket) {
    // check if we support this connection
    if (!httpReq.headers.get("Connection", "").equalsIgnoreCase("upgrade") ||
        !httpReq.headers.get("Upgrade", "").equalsIgnoreCase("websocket") ||
        httpReq.headers.get("Sec-WebSocket-Version", "") != "13" ||
        httpReq.headers.get("Sec-WebSocket-Key", "") == "")
      return ProtocolRes.skip

    in := socket.in
    out := socket.out
    try {
      handshakeReq := WsHandshakeReq(httpReq)
      _processor = processorFunc.call(handshakeReq)
      if (_processor == null)
        return ProtocolRes.close // connection has been processed
      WsHandshakeRes handshakeRes := _processor.onHandshake(handshakeReq)

      out.writeChars("HTTP/1.1 101 Switching Protocols\r\n")
         .writeChars("Upgrade: websocket\r\n")
         .writeChars("Connection: Upgrade\r\n")
         .writeChars("Sec-WebSocket-Accept: " + handshakeRes.accept + "\r\n")
      if (handshakeRes.protocol != null)
         out.writeChars("Sec-WebSocket-Protocol: " + handshakeRes.protocol + "\r\n")
      if (handshakeRes.extensions != null)
         out.writeChars("Sec-WebSocket-Extensions: " + handshakeRes.extensions + "\r\n")
      out.writeChars("\r\n").flush

      _conn = WsConnImpl(handshakeReq, socket, this)

      _processor.onReady(_conn)
      if (_conn.closed.val)
        try _processor.onClose(_conn); catch(Err e2) log.err("Error closing WebSocket", e2)
      return ProtocolRes.keep
    } catch(IOErr e) {
      log.debug("IO Error in WebSocket communication", e) // IOErrs are just ok
    } catch(Err e) {
      log.err("Error in WebSocket communication", e)
    }
    // if error happened, close everything
    if (_conn != null) {
      _conn.closed.val = true
      try _processor.onClose(_conn); catch(Err e2) log.err("Error closing WebSocket", e2)
    }
    return ProtocolRes.close
  }
  
  override ProtocolRes onNextConnections(TcpSocket socket) {
    try {
      if (!_conn.closed.val) {
        msg := _conn.read
        if (msg != null && !_conn.closed.val) {
          _processor.onMsg(_conn, msg)
          return ProtocolRes.keep
        }
      }
    } catch(IOErr e) { // IOErrs are just ok
      log.debug("IOErr in web socket communication", e)
    } catch(Err e) {
      log.err("Error in WebSocket communication", e)
    }
    _conn.closed.val = true
    try _processor.onClose(_conn); catch(Err e) log.err("Error closing WebSocket", e)
    return ProtocolRes.close
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
  abstract Obj? read()
  
  ** Write text message to the WebSocket.
  abstract Void writeStr(Str msg)
  
  ** Write text message to the WebSocket.
  abstract Void writeBinary(Buf msg)
  
  ** Finish WebSocket communication. After this method called it’s impossible 
  ** to write or read to/from this connection anymore.
  abstract Void close()
}

const class WsConnImpl : WsConn {
  override const WsHandshakeReq req
  
  const Unsafe     socketUnsafe
        TcpSocket  socket() { socketUnsafe.val }
  const AtomicBool reading := AtomicBool(false)
  const AtomicBool closed  := AtomicBool(false)
  const WsProtocol protocol
  
  internal new make(WsHandshakeReq req, TcpSocket socket, WsProtocol protocol) {
    this.req = req
    this.socketUnsafe = Unsafe(socket)
    this.protocol = protocol
  }
  
  override Obj? read() {
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
      msg := WsChannel.read(socket.in, socket.out)
      if (msg == null) close
      return msg
    } finally {
      reading.val = false
    }
  }
  
  override Void writeStr(Str msg) {
    if (!closed.val && !socket.isClosed)
      WsChannel.sendStr(msg, socket.out)
  }
  
  override Void writeBinary(Buf msg) {
    if (!closed.val && !socket.isClosed)
      WsChannel.sendBinary(msg, socket.out)
  }
  
  override Void close() {
    if (closed.compareAndSet(false, true))
      try {
        WsChannel.close(socket.out)
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
  virtual Void onMsg(WsConn conn, Obj msg) {}
  
  ** When client has closed connection. It’s invalid to read/send messages from/to 'conn' in this method.
  virtual Void onClose(WsConn conn) {}
}

const class WsHandshakeReq {
  const Str key
  const Str? protocols
  const Str version
  const Str host
  const Str origin
  const Uri uri

  new make(HttpReq req) {
    uri       = req.uri
    h        := req.headers
    key       = h["Sec-WebSocket-Key"]
    origin    = h["Origin"]
    host      = h["Host"]
    protocols = h["Sec-WebSocket-Protocol"]
    version   = h["Sec-WebSocket-Version"]
  }

  new makeTest(|This|? f := null) { f?.call(this) }
}

const class WsHandshakeRes {
  const Str? protocol
  const Str? extensions
  const Str  accept
  new make(WsHandshakeReq req, |This|? f := null) {
    accept = (req.key+"258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toBuf.toDigest("SHA1").toBase64
    f?.call(this)
  }
}

const mixin WsChannel {
  static Void sendStr(Str msg, OutStream out) {
    WsFrame { data = msg.toBuf; opcode = WsOpcode.text }.write(out)
  }

  static Void sendBinary(Buf msg, OutStream out) {
    WsFrame { data = msg; opcode = WsOpcode.binary }.write(out)
  }

  static Obj? read(InStream in, OutStream out) {
    msg            := Buf()
    WsOpcode? type := null
    while (true) {
      frame := WsFrame.read(in)
      if (frame.opcode == WsOpcode.close)
        return null
      if (frame.opcode == WsOpcode.ping) {
        WsFrame { data = frame.data; opcode = WsOpcode.pong }.write(out)
        continue
      }
      if (type == null)
        type = frame.opcode
      msg.writeBuf(frame.data)
      if (frame.fin)
        break
    }
    if (type == WsOpcode.binary) return msg
    return msg.seek(0).readAllStr
  }

  static Void close(OutStream out, Int? code := 1000, Str? reason := null) {
    msg := Buf()
    if (code != null)   msg.writeI2(code)
    if (reason != null) msg.writeUtf(reason)
    WsFrame { data = msg; opcode = WsOpcode.close }.write(out)
  }
}

class WsFrame {
  const Bool fin  := true
  const Bool rsv1 := false
  const Bool rsv2 := false
  const Bool rsv3 := false
  const WsOpcode opcode := WsOpcode.text
  Buf data

  new make(|This| f) { f.call(this) }


  Void write(OutStream out) {
    out.write((fin ? 0x80 : 0).or(rsv1 ? 0x40 : 0).or(rsv2 ? 0x20 : 0).or(rsv3 ? 0x10 : 0).or(opcode.ordinal.and(0x0f)))
    len := data.remaining
    if (len <= 125)         out.write(len)
    else if (len <= 0xFFFF) out.write(126).writeI2(len)
    else                    out.write(127).writeI8(len)

    out.writeBuf(data).flush
  }

  new read(InStream in) {
    // read first byte containing fin, rsv1, rsv2, rsv3 and the operation code
    b1 := in.read
    if (b1 == null) throw IOErr("Cannot read data frame (first byte)")
    fin  = b1.and(0x80) != 0
    rsv1 = b1.and(0x40) != 0
    rsv2 = b1.and(0x20) != 0
    rsv3 = b1.and(0x10) != 0
    opcode = WsOpcode.vals[b1.and(0x0F)]

    // read the second byte containing whether the is a mask or not and the length of the payload data
    // if the length is 126 then next 2 bytes are used to store the length and for 127 the next 8 bytes
    b2 := in.read
    if (b2 == null)        throw IOErr("Cannot read data frame (second byte)")
    // check MASK bit, MUST be set on messages from clients
    if (b2.and(0x80) == 0) throw IOErr("Client data should be masked")
    len := b2.and(0x7F)
    len = len == 126 ? in.readU2 : (len == 127 ? in.readS8 : len)
    maskingKey := in.readU4

    // read the payload data
    data = in.readBufFully(null, len)
    unmask(data, maskingKey)
  }

  static Buf unmask(Buf data, Int key) {
    // split up the key in its 4 bytes (maskingKey is only a 32bit integer)
    Int[] mask := [key.shiftr(24).and(0xff), key.shiftr(16).and(0xff), key.shiftr(8).and(0xff), key.and(0xff)]
    for (i := 0; i < data.size; ++i)
      data[i] = data[i].xor(mask[i % 4])
    return data
  }
}

enum class WsOpcode {
  continuation, text, binary, reserved3, reserved4, reserved5, reserved6, reserved7,
  close, ping, pong, reservedB, reservedC, reservedD, reservedE, reservedF
}

