
using concurrent

abstract const class WebSocketProtocol : Protocol {
  private static const Log log := Log.find("spectre")
  
  override Bool onConnection(HttpReq req) {
    if (!req.headers.get("Connection", "").equalsIgnoreCase("upgrade") ||
        !req.headers.get("Upgrade", "").equalsIgnoreCase("websocket"))
      return false

    socket := req.socket
    in := socket.in
    out := socket.out
    
    handshake := WebSocketHandshakeReq(req)
    handshakeRes := onHandshake(handshake, out)
    processor := handshakeRes.processor

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
    
    key3 := req.in.readBufFully(null, 8)
    out.writeBuf(handshakeRes.challenge(key3)).flush

    // There’s no timeout for client’s messages
    // TODO how will this be stopped?
    socket.options.receiveTimeout = null
    
    try {
      while (true) {
        frame := WebSocketDataFrame_HIXIE_76.read(req.in)
        if (frame == null)
          break
        onMessage(processor, frame.data)
        // TODO how would Actor close connection?
      }
    } catch(Err e) {
      log.err("Error in WebSocket communication", e)
    }
    return true
  }  

  abstract WebSocketHandshakeRes onHandshake(WebSocketHandshakeReq req, OutStream out)
  abstract Void onMessage(Actor processor, Buf data)
}


const class WebSocketHandshakeReq {
  new makeTest(|This|? f := null) { f?.call(this) }
  
  new make(HttpReq req) {
    h := req.headers
    resource = req.uri.pathStr
    key1 = h["Sec-WebSocket-Key1"]
    key2 = h["Sec-WebSocket-Key2"]
    origin = h["Origin"]
    host = h["Host"]
    protocols = h["Sec-WebSocket-Protocol"]
  }
  
  const Str key1
  const Str key2
  const Str? protocols
  const Str host
  const Str origin
  const Str resource
  const Bool secure := false
}

const class WebSocketHandshakeRes {

  const Str? protocol
  const Str location
  const Str origin
  
  // FIXME this should not be nullable
  const Actor? processor
  
  internal const Int part1
  internal const Int part2
  
  new make(WebSocketHandshakeReq req, |This|? f := null) {
    protocol = req.protocols
    origin = req.origin
    location = (origin.startsWith("https") ? "wss" : "ws") + "://" + req.host + req.resource
    
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

** draft-hixie-thewebsocketprotocol-76
class WebSocketDataFrame_HIXIE_76 {
  Buf data

  new make(|This| f) { f.call(this) }
  
  Void write(OutStream out) {
    out.write(0x00).writeBuf(data).write(0xFF).flush
  }
  
  static WebSocketDataFrame_HIXIE_76? read(InStream in) {
    b := in.read
    if (b != 0x00) {
      if (b == null || (b == 0xFF && in.read == 0x00)) // FIXME setUp readTimeout
        return null
      
      throw IOErr("Protocol error")
    }

    buf := Buf()
    while(true) { 
      b = in.read // TODO read buf, not single byte
      if (b == null)
        throw IOErr("Protocol error")
      if (b == 0xFF)
        break
      buf.write(b)
    }

    return WebSocketDataFrame_HIXIE_76 { data = buf.seek(0) }
  }
  
  Void close(OutStream out) {
    out.write(0xFF).write(0x00).flush
    // TODO do smth with this method
  }
}


** draft-ietf-hybi-thewebsocketprotocol-03 protocol
const class WebSocketDataFrame_IETF_03 {
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
  const Str data
  
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
    out.writeChars(data).flush
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
    data = in.readBufFully(null, len).readAllStr
  }
}
