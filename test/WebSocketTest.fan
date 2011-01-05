class WebSocketTest : Test {
  
  Str req := """GET / HTTP/1.1
                Connection: Upgrade
                Host: example.com
                Upgrade: WebSocket
                Sec-WebSocket-Key1: 3e6b263  4 17 80
                Origin: http://example.com
                Sec-WebSocket-Key2: 17  9 G`ZD9   2 2b 7X 3 /r90

                WjN}|M(6"""
                  

  Void testHandshake() {
    req := WebSocketHandshakeReq {
      key1 = "3e6b263  4 17 80"
      key2 = "17  9 G`ZD9   2 2b 7X 3 /r90"
      key3 = Buf().writeChars("WjN}|M(6").seek(0)
      resource = "/" 
      host = "example.com"
      origin = "http://example.com"
    }
    
    verifyEq(req.keyNumber1, 3626341780)
    verifyEq(req.keyNumber2, 1799227390)
    
    verifyEq(req.spaces1, 4)
    verifyEq(req.spaces2, 10)
    
    verifyEq(req.part1, 906585445)
    verifyEq(req.part2, 179922739)
    
    verifyEq(req.challenge.toHex, "360965650ab96733576a4e7d7c4d2836")
    verifyEq(req.response.toHex, "6e603965426b397a245238704f745662")
  }
  
  Void testDataFrame() {
    res := Buf()
    
    d := WebSockedDataFrame { data = "Hello" }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0405" + "Hello".toBuf.toHex)
    
    // fragmented
    d = WebSockedDataFrame { data = "Hel"; more = true }
    d.write(res.clear.out)
    verifyEq(res.toHex, "8403" + "Hel".toBuf.toHex)
    
    // continuation
    d = WebSockedDataFrame { data = "lo"; more = false; opcode = continuation }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0002" + "lo".toBuf.toHex)
    
    // ping
    d = WebSockedDataFrame { data = "Hello"; opcode = ping }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0205" + "Hello".toBuf.toHex)
    
    // pong
    d = WebSockedDataFrame { data = "Hello"; opcode = pong }
    d.write(res.clear.out)
    verifyEq(res.toHex, "0305" + "Hello".toBuf.toHex)
    
    // 256 bytes binary
    d = WebSockedDataFrame { data = Buf.random(256/2).toHex; opcode = binary }
    d.write(res.clear.out)
    verifyEq(res.seek(0).readBufFully(null, 4).toHex, "057e0100", "res.toHex: " + res.toHex)
    
    // 64KiB bytes binary
    d = WebSockedDataFrame { data = Buf.random(65536/2).toHex; opcode = binary }
    d.write(res.clear.out)
    verifyEq(res.seek(0).readBufFully(null, 10).toHex, "057f0000000000010000", "res.toHex: " + res.toHex)
  }  
}
