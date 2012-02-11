class WebSocketTest : Test {
  Void testHandshake() {
    req := WsHandshakeReq.makeTest {
      key = "dGhlIHNhbXBsZSBub25jZQ=="
      uri  = `http://example.com/` 
      host = "example.com"
      origin = "http://example.com"
      version = "13"
    }
    
    res := WsHandshakeRes(req)

    verifyEq(res.accept, "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")
  }
  
  Void testDataWsFrame_readWrite() {
    res := Buf()
    
    // single-frame unmasked text message
    d := WsFrame { data = "Hello".toBuf }
    d.write(res.clear.out)
    verifyEq(res.toHex, "810548656c6c6f")
    verifyEq(WsFrame.read(res.seek(0).in).data.readAllStr, "Hello")
    
    // single-frame masked text message
    d = WsFrame { data = "Hello".toBuf; mask = true }
    d.write(res.clear.out)
    verifyEq(WsFrame.read(res.seek(0).in).data.readAllStr, "Hello")
    
    // fragmented unmasked text message
    d = WsFrame { data = "Hel".toBuf; fin = false }
    d.write(res.clear.out)
    verifyEq(res.toHex, "010348656c")
    frame := WsFrame.read(res.seek(0).in)
    verifyEq(frame.data.readAllStr, "Hel")
    verify(!frame.fin)
    verifyEq(frame.opcode, WsOpcode.text)
    
    d = WsFrame { data = "lo".toBuf; opcode = WsOpcode.continuation; }
    d.write(res.clear.out)
    verifyEq(res.toHex, "80026c6f")
    frame = WsFrame.read(res.seek(0).in)
    verifyEq(frame.data.readAllStr, "lo")
    verify(frame.fin)
    verifyEq(frame.opcode, WsOpcode.continuation)
  }  
}
