
class QueryMapTest : Test {
  private Void verifyQueryMap(QueryMap qm, Map expected) {
    verifyEq(qm, QueryMap.make(expected))
  }
  
  private Void verifySetEq(Obj o1, Obj o2) {
    o1->each { verify(o2->contains(it)) }
    o2->each { verify(o1->contains(it)) }
  }
  
  Void testIdentity() {
    qm1 := QueryMap.make().set("a", "b").set("c", "d")
    qm2 := QueryMap.make().setList("a", ["b"]).setList("c", ["d"])
    qm3 := QueryMap.make().setList("c", ["d"]).setList("a", ["b"])    
    
    verifyEq(qm1.impl["a"], qm2.impl["a"])
    verifyEq(qm1.impl["c"], qm2.impl["c"])
    verifyEq(qm1, qm2)
    verifyEq(qm1, qm3)
  }
  
  Void testModifications() {
    qm1 := QueryMap.make().set("a", "b").set("c", "d")
    qm1.set("e", "f")
    verifyQueryMap(qm1, ["a": "b", "c": "d", "e": "f"])

    qm1.add("g", "h")
    verifyQueryMap(qm1, ["a": "b", "c": "d", "e": "f", "g": "h"])
    qm1.add("g", "i")
    verifyEq(qm1.getList("g"), ["h", "i"])
    
    qm1.setList("j", ["k", "l"])
    verifyQueryMap(qm1, ["a": "b", "c": "d", "e": "f", "g": ["h", "i"], "j": ["k", "l"]])
    
    qm1.addList("a", ["i", "k"])
    verifyEq(qm1.getList("a"), ["b", "i", "k"])
  }
  
  Void testRoRw() {
    qm1 := QueryMap.make().set("a", "b").set("c", "d")
    qm1.setList("j", ["k", "l"])
    
    verifyErr(ReadonlyErr#) { qm1.ro.setList("j", ["k", "l"]) }
    qm1.setList("j", ["k", "l"])
    qm1.ro.rw.setList("j", ["k", "l"])
    verify(qm1.isRW)
    verify(qm1.ro.isRO)
    verify(qm1.ro.rw.isRW)
  }
  
  Void testViews() {
    qm1 := QueryMap.make().set("a", "b").set("c", "d")
    qm1.set("e", "f")
    qm1.add("g", "h")
    qm1.setList("j", ["k", "l"])
    
    verifyEq(qm1.size, 5)
    verifySetEq(qm1.asMap.keys, Str["a", "c", "e", "g", "j"])
    verifySetEq(qm1.asMap.vals, Str["b", "d", "f", "h", "l"])
    verifyEq(qm1.asMultimap.vals, Str[][["b"], ["d"], ["f"], ["h"], ["k", "l"]])
//    verifyEq(qm1.asMultimap.valsListsFlat, Str["b", "d", "f", "h", "k", "l"])
    
    verifyQueryMap(qm1.dup, ["a": "b", "c": "d", "e": "f", "g": "h", "j": ["k", "l"]])
  }
  
  Void testRemoves() {
    qm1 := QueryMap.make(["a": ["b","c","d"], "b": ["e", "f", "g"], "c": ["i"], "d": "", "e": Str[,]])
    
    qm2 := qm1.dup
    qm3 := qm1.dup
    verifyEq(qm1.get("a"), "d")
    verifyEq(qm1.remove("a"), "d")
    verifyEq(qm1.remove("b"), "g")
    verifyEq(qm1.remove("c"), "i")
    verifyEq(qm1.remove("d"), "")
    verifyEq(qm1.remove("e"), "")
    verifyEq(qm1.remove("f"), null)
    
    verifyEq(qm2.size, 5) // nothing was removed from dup
    verifyEq(qm2.getList("a"), ["b", "c", "d"])
    verifyEq(qm2.removeList("a"), ["b", "c", "d"])
    verifyEq(qm2.removeList("b"), ["e", "f", "g"])
    verifyEq(qm2.removeList("c"), ["i"])
    verifyEq(qm2.removeList("d"), [""])
    verifyEq(qm2.removeList("e"), Str[,])
    verifyEq(qm2.removeList("f"), null)
  }
  
//  Void testDefaults() {
//    qm3 := QueryMap.make(["a": ["b","c","d"], "b": ["e", "f", "g"], "c": ["i"], "d": "", "e": Str[,]])
//    
//    qm3.def = "abc"
//    verifyEq(qm3.getList("a"), ["b", "c", "d"])
//    verifyEq(qm3.get("x"), "abc")
//    verifyEq(qm3.getList("x"), ["abc"])
//    
//    verifyEq(qm3.getList("a", ["def"]), ["b", "c", "d"])
//    verifyEq(qm3.get("x", "def"), "def")
//    verifyEq(qm3.getList("x", ["def", "def2"]), ["def", "def2"])
//    
//    qm3.defList = ["abc", "xyz"]
//    verifyEq(qm3.getList("a"), ["b", "c", "d"])
//    verifyEq(qm3.get("x"), "xyz")
//    verifyEq(qm3.getList("x"), ["abc", "xyz"])
//
//    qm3.defList = null
//    verifyEq(qm3.get("x"), null)
//    verifyEq(qm3.getList("x"), null)
//    
//    qm3.def = null
//    verifyEq(qm3.get("x"), null)
//    verifyEq(qm3.getList("x"), null)
//  }
  
  Void testKeysWithoutValues() {
    qm3 := QueryMap.make(["a": ["b","c","d"], "b": ["e", "f", "g"], "c": ["i"], "d": "", "e": Str[,]])
//    qm3.def = "abc"
    
    qm3["y"] = ""
    qm3.setList("z", Str[,])

    verifyEq(qm3.get("y"), "")
    verifyEq(qm3.getList("y"), [""])
    verifyEq(qm3.get("y", "def"), "")
    verifyEq(qm3.getList("y", ["def"]), [""])
    
    verifyEq(qm3.get("z"), "")
    verifyEq(qm3.getList("z"), Str[,])
    verifyEq(qm3.get("z", "def"), "")
    verifyEq(qm3.getList("z", ["def"]), Str[,])
  }
  
  private Void verifyDecode(Str queryStr, Map expected) {
    verifyEq(QueryMap.decodeQuery(queryStr), QueryMap.make(expected))
  }
  
  Void testDecodeQuery() {
    verifyDecode("a",       ["a": ""])
    verifyDecode("a_b!",    ["a_b!": ""])
    verifyDecode("a=b",     ["a": "b"])
    verifyDecode("a=beta",  ["a": "beta"])
    verifyDecode("alpha=b", ["alpha": "b"])
    verifyDecode("alpha=b;",       ["alpha": "b"])
    verifyDecode("alpha=b&",       ["alpha": "b"])
    verifyDecode("alpha=b;;&;&",   ["alpha": "b"])
    
    verifyDecode("alpha=b&c",      ["alpha": "b", "c": ""])
    verifyDecode("a=b&;&charlie;", ["a": "b", "charlie": ""])
    
    verifyDecode("a=b&c=d", ["a": "b", "c": "d"])
    verifyDecode("a=b;c=d", ["a": "b", "c": "d"])

    //multiple values
    verifyDecode("x=1&x=2&y=9&x=3",["x": ["1", "2", "3"], "y": "9"])
    
    //escapes
    verifyDecode("a=b\\&c\\=d", ["a": "b&c=d"])
    verifyDecode(Str <|a=h2\=\=;b\\b=c&d\;e|>, ["a": "h2==", "b\\b": "c", "d;e": ""])
    verifyDecode(Str <|\\\;\&\#=\#\&\=\;\\|>, ["\\;&#":"#&=;\\"])
    
    verifyDecode("x=Hello%3Dworld", ["x": "Hello=world"])
    verifyDecode("x=Hello+world", ["x": "Hello world"])
  }

  Void testEncode() {
    verifyEq(QueryMap.make.setList("a", ["b", "c", "d"]).set("e", "f").set("g", "").encode, "a=b&a=c&a=d&e=f&g=")
    verifyEq(QueryMap.encodeQuery(["a": ["b,c,d"]]), "a=b,c,d")
    verifyEq(QueryMap.encodeQuery(["a": ["b=c&d=e"]]), "a=b%3Dc%26d%3De")
    
    verifyEq(QueryMap.encodeQuery(["a": ["Hello world"]]), "a=Hello%20world")
    verifyEq(QueryMap.encodeQuery(["a": ["Hello;world&x=y"]]), "a=Hello%3Bworld%26x%3Dy")
    verifyEq(QueryMap.encodeQuery(["a": ["абюя"]]), "a=%D0%B0%D0%B1%D1%8E%D1%8F")
  }
  
  Void testDecodeParts() {
    verifyEq(QueryMap.nextOctet("abcdef", 0), ['a', 1])
    verifyEq(QueryMap.nextOctet("abcdef", 2), ['c', 3])
    verifyEq(QueryMap.nextOctet("abcdef", 5), ['f', 6])
    
    verifyEq(QueryMap.nextOctet("%20", 0), [' ', 3])
    verifyEq(QueryMap.nextOctet("%20ab", 0), [' ', 3])
    verifyEq(QueryMap.nextOctet("a%20b", 1), [' ', 4])    
    verifyEq(QueryMap.nextOctet("ab%20", 2), [' ', 5])

    verifyEq(QueryMap.nextOctet("+ab", 0), [' ', 1])
    verifyEq(QueryMap.nextOctet("a+b", 1), [' ', 2])    
    verifyEq(QueryMap.nextOctet("ab+", 2), [' ', 3])
    
    verifyErr(ParseErr#) { QueryMap.nextOctet("ab%2", 2) }
    verifyErr(ParseErr#) { QueryMap.nextOctet("ab%0g", 2) }
    
    // next char
    verifyEq(QueryMap.nextChar("abcdef", 0), ['a', 1])
    verifyEq(QueryMap.nextChar("abcdef", 2), ['c', 3])
    verifyEq(QueryMap.nextChar("abcdef", 5), ['f', 6])
    
    verifyEq(QueryMap.nextChar("%20", 0), [' ', 3])
    verifyEq(QueryMap.nextChar("%20ab", 0), [' ', 3])
    verifyEq(QueryMap.nextChar("a%20b", 1), [' ', 4])    
    verifyEq(QueryMap.nextChar("ab%20", 2), [' ', 5])

    verifyEq(QueryMap.nextChar("+ab", 0), [' ', 1])
    verifyEq(QueryMap.nextChar("a+b", 1), [' ', 2])    
    verifyEq(QueryMap.nextChar("ab+", 2), [' ', 3])
    
    verifyErr(ParseErr#) { QueryMap.nextChar("ab%2", 2) }
    verifyErr(ParseErr#) { QueryMap.nextChar("ab%0g", 2) }
    
    verifyEq(QueryMap.nextChar("%D0%B0%D0%B1%D1%8E%D1%8F", 0), ['а', 6])
//    verifyErr(ParseErr#) { QueryMap.nextChar("%D0%B0%D0%B1%D1%8E%D1%8F", 3) }
    verifyEq(QueryMap.nextChar("%D0%B0%D0%B1%D1%8E%D1%8F", 3), ['\u00b0', 6])
    verifyEq(QueryMap.nextChar("%D0%B0%D0%B1%D1%8E%D1%8F", 6), ['б', 12])
    verifyEq(QueryMap.nextChar("%D0%B0%D0%B1%D1%8E%D1%8F", 12), ['ю', 18])
    verifyEq(QueryMap.nextChar("%D0%B0%D0%B1%D1%8E%D1%8F", 18), ['я', 24])
    
    verifyEq(QueryMap.nextOctet("абв", 0), ['а', 1])
    verifyEq(QueryMap.nextOctet("абв", 1), ['б', 2])    
    verifyEq(QueryMap.nextOctet("абв", 2), ['в', 3])
  }
}
