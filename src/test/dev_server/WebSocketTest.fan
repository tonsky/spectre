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

  Void testMasking() {
    key  := 0x12345678
    data := "Hello".toBuf // "48656c6c6f"
    verifyEq(data.toHex, "48656c6c6f")
    WsFrame.unmask(data, key)
    verifyEq(data.toHex, "5a513a147d") // encoded
    WsFrame.unmask(data, key)
    verifyEq(data.toHex, "48656c6c6f") // decoded
  }

  Void testWrite() {
    res := Buf()
    WsChannel.sendStr("Hello", res.clear.out)
    verifyEq(res.toHex, "810548656c6c6f")

    WsChannel.sendBinary("Hello".toBuf, res.clear.out)
    verifyEq(res.toHex, "820548656c6c6f")

    WsChannel.sendBinary(Buf.random(256), res.clear.out)
    verifyEq(res.toHex[0..<8], "827e0100")

    WsChannel.sendBinary(Buf.random(65536), res.clear.out)
    verifyEq(res.toHex[0..<20], "827f0000000000010000")
  }

  Void testRead() {
    text      := stringFrame(true,  1, true, "To be or not to be?")
    text2     := stringFrame(true,  1, true, "That is the question.")
    textStart := stringFrame(false, 1, true, "Roses are ")
    textCont  := stringFrame(false, 0, true, "red, violets are ")
    textEnd   := stringFrame(true,  0, true, "blue")
    ping      := stringFrame(true,  9, true, "Hello")
    close     := binaryFrame(true,  8, true, Buf().writeI2(1000).writeUtf("Normal close").seek(0))
    binary    := binaryFrame(true,  2, true, "Hello".toBuf)
    in := Buf()
    out := Buf()
   
    // single text frame
    verifyEq("To be or not to be?", WsChannel.read(text.seek(0).in, out.clear.out))
    verifyEq(0, out.size)

    // frame with continuation
    in = Buf()
      .writeBuf(textStart.seek(0))
      .writeBuf(textEnd.seek(0))
    verifyEq("Roses are blue", WsChannel.read(in.seek(0).in, out.clear.out))
    verifyEq(0, out.size)
    
    // frame with 2 continuations
    in = Buf()
      .writeBuf(textStart.seek(0))
      .writeBuf(textCont.seek(0))
      .writeBuf(textEnd.seek(0))
    verifyEq("Roses are red, violets are blue", WsChannel.read(in.seek(0).in, out.clear.out))
    verifyEq(0, out.size)
    
    // frames with ping interleaved
    in = Buf()
      .writeBuf(textStart.seek(0))
      .writeBuf(ping.seek(0))
      .writeBuf(textEnd.seek(0))
    verifyEq("Roses are blue", WsChannel.read(in.seek(0).in, out.clear.out))
    verifyEq("8a0548656c6c6f", out.seek(0).toHex)
    
    in = Buf()
      .writeBuf(ping.seek(0))
      .writeBuf(textStart.seek(0))
      .writeBuf(ping.seek(0))
      .writeBuf(textCont.seek(0))
      .writeBuf(ping.seek(0))
      .writeBuf(textEnd.seek(0))
    verifyEq("Roses are red, violets are blue", WsChannel.read(in.seek(0).in, out.clear.out))
    verifyEq("8a0548656c6c6f8a0548656c6c6f8a0548656c6c6f", out.seek(0).toHex)
    
    // two messages
    in = Buf()
      .writeBuf(ping.seek(0))
      .writeBuf(text.seek(0))
      .writeBuf(ping.seek(0))
      .writeBuf(text2.seek(0))
    verifyEq("To be or not to be?", WsChannel.read(in.seek(0).in, out.clear.out))
    verifyEq("That is the question.", WsChannel.read(in.in, out.out))
    verifyEq("8a0548656c6c6f8a0548656c6c6f", out.seek(0).toHex)

    // closing not finished msg
    in = Buf()
      .writeBuf(textStart.seek(0))
      .writeBuf(textCont.seek(0))
      .writeBuf(close.seek(0))
      .writeBuf(textEnd.seek(0))
    verifyEq(null, WsChannel.read(in.seek(0).in, out.clear.out))
    verifyEq(0, out.size)

    in = Buf()
      .writeBuf(binary.seek(0))
    verifyEq("48656c6c6f", (WsChannel.read(in.seek(0).in, out.clear.out) as Buf).seek(0).toHex)
    verifyEq(0, out.size)
  }

  Buf stringFrame(Bool fin, Int opcode, Bool mask, Str str) {
    return binaryFrame(fin, opcode, mask, str.toBuf)
  }

  Buf binaryFrame(Bool fin, Int opcode, Bool mask, Buf data) {
    res := Buf()
    res.write((fin?0x80:0).or(opcode))
    len := data.size
    Int maskBit := mask ? 0x80 : 0
    if (len <= 125)         res.write(maskBit.or(len))
    else if (len <= 0xFFFF) res.write(maskBit.or(126)).writeI2(len)
    else                    res.write(maskBit.or(127)).writeI8(len)
    maskingKey := Int.random.and(0xFFFFFFFF)
    if (mask) {
      res.writeI4(maskingKey)
      WsFrame.unmask(data, maskingKey)
    }
    res.writeBuf(data)
    return res
  }
}
