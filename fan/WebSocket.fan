
using concurrent
using util
using web

class WebSocketServer : AbstractMain {
  @Opt { help = "http port" }
  Int port := 8080

  override Int run() {
    return runServices([ DevServer { it.port = this.port } ])
  }
}

const class WebSocketWeblet : WebMod {
  override Void onService() {
    echo("Connection accepted")
    try {    
      h := req.headers
      if (h["Connection"] != "Upgrade") {
        echo("Connection: " + h["Connection"])
        return
      }
      if (h["Upgrade"] != "WebSocket") {
        echo("Upgrade: " + h["Upgrade"])
        return
      }
      
      echo("Reading")
      key3Buf := req.in.readBufFully(null, 8)
      echo("Read " + key3Buf.toHex)
      
      wsReq := WebSocketHandshakeReq {
        key1 = h["Sec-WebSocket-Key1"]
        key2 = h["Sec-WebSocket-Key2"]
        key3 = key3Buf
        origin = h["Origin"]
        host = h["Host"]
        protocols = h["Sec-WebSocket-Protocol"]
        resource = req.uri.pathStr
      }
      
      
      res.statusCode = 101
      res.headers["Connection"] = "Upgrade"
      res.headers["Upgrade"] = "WebSocket"
      res.headers["Sec-WebSocket-Location"] = "ws://" + wsReq.host + wsReq.resource 
      res.headers["Sec-WebSocket-Origin"] = wsReq.origin
      res.headers["Content-Length"] = wsReq.response.size.toStr
      
      res.out.writeBuf(wsReq.response)
      
      d := WebSockedDataFrame { data = "Hello websocket!" }
      d.write(res.out)
      
      d = WebSockedDataFrame { data = "Hello again!" }
      d.write(res.out)
      
      echo("Connection processed")
    } catch(Err e){
      e.trace
    }
  }
}

//TODO const
class WebSocketHandshakeReq {
  Str key1
  Str key2
  Buf key3
  Str? protocols
  Str host
  Int port := 80
  Str origin
  Str resource
  Bool secure := false
  
  new make(|This| f) { f.call(this) }
  
  Int keyNumber1() { keyToNum(key1) }
  Int keyNumber2() { keyToNum(key2) }
  Int spaces1() { spaces(key1) }
  Int spaces2() { spaces(key2) }
  
  Int part1() { keyToNum(key1) / spaces(key1) }
  Int part2() { keyToNum(key2) / spaces(key2) }
  
  once Buf challenge() {
    buf := Buf(16) { endian = Endian.big }
    buf.writeI4(part1)
    buf.writeI4(part2)
    buf.writeBuf(key3, 8)
    return buf
  }
  once Buf response() { challenge.toDigest("MD5") }
  
  Int keyToNum(Str key) {
    digits := key.chars.findAll { it.isDigit }
    return Str.fromChars(digits).toInt
  }
  
  Int spaces(Str key) {
    amount := 0
    key.chars.each { if (it == ' ') ++amount }
    return amount
  }
}

const class WebSockedDataFrame {
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
    out.writeChars(data)
  }
}
