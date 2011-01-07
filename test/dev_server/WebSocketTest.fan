class WebSocketTest : Test {
  Void testHandshake() {
    req := WebSocketHandshakeReq.makeTest {
      key1 = "3e6b263  4 17 80"
      key2 = "17  9 G`ZD9   2 2b 7X 3 /r90"
      resource = "/" 
      host = "example.com"
      origin = "http://example.com"
    }
    
    key3 := Buf().writeChars("WjN}|M(6").seek(0)
    res := WebSocketHandshakeRes(req)

    verifyEq(res.challenge(key3).toHex, "6e603965426b397a245238704f745662")
  }
  
  Void testDataFrame_HIXIE_76_write() {
    res := Buf()
    d := WebSocketDataFrame_HIXIE_76() { data = "Hello".toBuf }
    d.write(res.clear.out)
    verifyEq(res.toHex, "00" + "Hello".toBuf.toHex + "ff")
  }

  
  Void testDataFrame_HIXIE_76_read() {
    res := Buf().write(0x00).writeChars("Hello").write(0xFF)
                .writeChars("abc").write(0x00).writeChars("def").write(0xFF)
    d := WebSocketDataFrame_HIXIE_76.read(res.seek(0).in)
    verifyEq(d.data.readAllStr, "Hello")
    verifyErr(IOErr#) { WebSocketDataFrame_HIXIE_76.read(res.in) }
    
    res = Buf().write(0x00).write(0xFF)
    d = WebSocketDataFrame_HIXIE_76.read(res.seek(0).in)
    verifyEq(d.data.readAllStr, "")
    
    // closing handshake
    res = Buf().write(0xFF).write(0x00)
    d = WebSocketDataFrame_HIXIE_76.read(res.seek(0).in)
    verifyEq(d, null)
  }

  Void testDataFrame_IETF_03_read() {
    // TODO when browsers catched up
  }
  
  Void testDataFrame_IETF_03_write() {
    res := Buf()
    
    d := WebSocketDataFrame_IETF_03 { data = "Hello" }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0405" + "Hello".toBuf.toHex)
    
    // fragmented
    d = WebSocketDataFrame_IETF_03 { data = "Hel"; more = true }
    d.write(res.clear.out)
    verifyEq(res.toHex, "8403" + "Hel".toBuf.toHex)
    
    // continuation
    d = WebSocketDataFrame_IETF_03 { data = "lo"; more = false; opcode = continuation }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0002" + "lo".toBuf.toHex)
    
    // ping
    d = WebSocketDataFrame_IETF_03 { data = "Hello"; opcode = ping }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0205" + "Hello".toBuf.toHex)
    
    // pong
    d = WebSocketDataFrame_IETF_03 { data = "Hello"; opcode = pong }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0305" + "Hello".toBuf.toHex)
    
    // 256 bytes binary
    d = WebSocketDataFrame_IETF_03 { data = Buf.random(256/2).toHex; opcode = binary }
    d.write(res.clear.out)
    verifyEq(res.seek(0).readBufFully(null, 4).toHex, "057e0100", "res.toHex: " + res.toHex)
    
    // 64KiB bytes binary
    d = WebSocketDataFrame_IETF_03 { data = Buf.random(65536/2).toHex; opcode = binary }
    d.write(res.clear.out)
    verifyEq(res.seek(0).readBufFully(null, 10).toHex, "057f0000000000010000", "res.toHex: " + res.toHex)
  }  
}
