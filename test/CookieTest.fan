
using spectre::Cookie

class CookieTest : Test {
  
  Void verifyEncodeDecode(Str from, Str expected, Bool expectQuotes := true) {
    if (expectQuotes)
      expected = "\"$expected\""
    some := Cookie()
    encoded := some.encode(from)
    verifyEq(encoded, expected, "Encoding failed, expected $expected, got $encoded")
//    if (encoded.size > 1 && encoded[0] == '"' && encoded[-1] == '"')
//      encoded = encoded[1..-2]
    decoded := Cookie.decode(encoded)
    verifyEq(decoded, from, "Decoding failed, expected $from, got $decoded")
  }
  
  Void testEncodeDecode() {
    // basics
    verifyEncodeDecode("", "", false)
    verifyEncodeDecode("a", "a", false)    
    
    // allowed chars
    verifyEncodeDecode("abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "0123456789" + "!#\$%&'*+-.^_`|~",
                       "abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "0123456789" + "!#\$%&'*+-.^_`|~", false)
    
    // strings with spaces are expected to be escaped
    verifyEncodeDecode("a b c", "a b c", true)
    
    // escaping
    verifyEncodeDecode("\"a\"", "\\\"a\\\"")
    verifyEncodeDecode("a\"\n\t\"\\adsdad", "a\\\"\\x0a\\x09\\\"\\\\adsdad")
    verifyEncodeDecode(",;\"\\", "\\x2c\\x3b\\\"\\\\")
    
    // non-ASCII test
    verifyEncodeDecode("тест", "\\u0442\\u0435\\u0441\\u0442")
    verifyEncodeDecode("another тест here", "another \\u0442\\u0435\\u0441\\u0442 here")
    
    // everything together
    verifyEncodeDecode("т\"е\nс;т,", "\\u0442\\\"\\u0435\\x0a\\u0441\\x3b\\u0442\\x2c")
    
    // and trying to fool our implementation
    verifyEncodeDecode("\\x2c\\u0442", "\\\\x2c\\\\u0442")
    verifyEncodeDecode(",00", "\\x2c00")
  }
  
  Void verifyLoad(Str src, Cookie[] expected) {
    Cookie[] actual := Cookie.load(src)
    actual.each |c, idx| {
      exp := expected[idx]
      verifyEq(c.name, exp.name)
      verifyEq(c.val, exp.val)
      verifyEq(c.toStr, exp.toStr)
      verifyEq(c.maxAge, exp.maxAge)
      verifyEq(c.domain, exp.domain)
      verifyEq(c.path, exp.path)
    }    
  }
  
  Void testLoad() {
    verifyLoad("a=b", [Cookie{ name="a"; val="b"}])
    verifyLoad("a=", [Cookie{ name="a"; val=""}])
    verifyLoad("a=;c=d", [Cookie{ name="a"; val=""}, Cookie{name="c"; val="d"}])
    verifyLoad("a=b; c=d", [Cookie{ name="a"; val="b"}, Cookie{ name="c"; val="d"}])
    verifyLoad(Str<|a="b c d"; c="d e f"|>, [Cookie{ name="a"; val="b c d" }, Cookie{ name="c"; val="d e f" }])
    verifyLoad(Str<|a="\"b c d\""|>, [Cookie{ name="a"; val="\"b c d\"" }])
    verifyLoad(Str<|a="b\" c \"d"; c="\"d e f\""|>, 
      [Cookie{ name="a"; val="b\" c \"d" }, Cookie{ name="c"; val="\"d e f\"" }])
    
    verifyLoad("keebler=\"E=mc2\\x3b L=\\\"Loves\\\"\\x3b fudge=\\x0a\\x3b\"",
      [Cookie{ name="keebler"; val="E=mc2; L=\"Loves\"; fudge=\n;"}])
  }
  
  Void testToStr() {
    verifyEq(Cookie { name="a"; val="b" }.toStr, "a=b;Path=/")
    verifyEq(Cookie { name="a"; val="b"; path="/"; domain="a.com"; secure=true }.toStr, "a=b;Domain=a.com;Path=/;Secure")
    verifyEq(Cookie { name="a"; val="b c d" }.toStr, "a=\"b c d\";Path=/")
    verifyEq(Cookie { name="a"; val="b;c=d" }.toStr, "a=\"b\\x3bc=d\";Path=/")

    // testing expires
    // TODO may fail on if second change after this call
    nextDay := (DateTime.nowUtc+Duration.fromStr("1day")).toHttpStr
    verifyEq(Cookie { name="a"; val="b"; maxAge = Duration.fromStr("1day") }.toStr, "a=b;Max-Age=86400;Expires=$nextDay;Path=/")
    verifyEq(Cookie { name="a"; maxAge = Duration.make(-1) }.toStr, "a=;Max-Age=0;Expires=Sat, 01 Jan 2000 00:00:00 GMT;Path=/")
    
    // incorrect names
    verifyErr(ArgErr#) { Cookie { name="a b c"; val = "b" }.toStr }
    verifyErr(ArgErr#) { Cookie { name="expires"; val = "b" }.toStr }
    verifyErr(ArgErr#) { Cookie { name="ExpireS"; val = "b" }.toStr }
  }
}
