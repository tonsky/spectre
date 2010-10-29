
class RouteTest : Test
{
  private Void _test(Str url, Matcher m, [Str:Str]? expected) {
    matchResult := m.match(RoutingMod.preparePath(url))
    verifyEq(expected, matchResult, "Got: $matchResult, expected: $expected on matching '$url' against $m")
  }
  
  Void testSimpleMatches() {
    m := Matcher.fromStr("/")
    _test("/",       m, Str:Str[:])
    _test("/test",   m, null)
    _test("/test/",  m, null)
    _test("/test2",  m, null)
    _test("/test2/", m, null)

    ["/test", "/test/"].each {
      m = Matcher.fromStr(it)
      _test("/",            m, null)
      _test("/test",        m, Str:Str[:])
      _test("/test/",       m, Str:Str[:])
      _test("/test/test2",  m, null)
      _test("/test/test2/", m, null)
    }

    ["/test/test2", "/test/test2/"].each {
      m = Matcher.fromStr(it)
      _test("/",            m, null)
      _test("/test",        m, null)
      _test("/test/",       m, null)
      _test("/test/test2",  m, Str:Str[:])
      _test("/test/test2/", m, Str:Str[:])
    }
  }
  
  Void testVariableCapturing() {
    ["/*", "/*/"].each {
      m := Matcher.fromStr(it)
      _test("/",            m, ["pathRest": ""])
      _test("/test",        m, ["pathRest": "test"])
      _test("/test/",       m, ["pathRest": "test"])
      _test("/test/test2",  m, ["pathRest": "test/test2"])
      _test("/test/test2/", m, ["pathRest": "test/test2"])
    }
    
    ["/{var}", "/{var}/"].each {
      m := Matcher.fromStr(it)
      _test("/",            m, null)
      _test("/test",        m, ["var": "test"])
      _test("/test/",       m, ["var": "test"])
      _test("/test/test2",  m, null)
      _test("/test/test2/", m, null)
    }
    
    ["/{var}/*", "/{var}/*/"].each {
      m := Matcher.fromStr(it)
      _test("/",                  m, null)
      _test("/test",              m, ["var": "test", "pathRest": ""])
      _test("/test/",             m, ["var": "test", "pathRest": ""])
      _test("/test/test2",        m, ["var": "test", "pathRest": "test2"])
      _test("/test/test2/",       m, ["var": "test", "pathRest": "test2"])
      _test("/test/test2/test3",  m, ["var": "test", "pathRest": "test2/test3"])
      _test("/test/test2/test3/", m, ["var": "test", "pathRest": "test2/test3"])
    }
    
    ["/{var}/{var2}", "/{var}/{var2}/"].each {
      m := Matcher.fromStr(it)
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",        m, ["var": "test", "var2": "test2"])
      _test("/test/test2/",       m, ["var": "test", "var2": "test2"])
      _test("/test/test2/test3",  m, null)
      _test("/test/test2/test3/", m, null)
    }
    
    ["/{var}/{var2}/*", "/{var}/{var2}/*/"].each {
      m := Matcher.fromStr(it)
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",              m, ["var": "test", "var2": "test2", "pathRest": ""])
      _test("/test/test2/",             m, ["var": "test", "var2": "test2", "pathRest": ""])
      _test("/test/test2/test3",        m, ["var": "test", "var2": "test2", "pathRest": "test3"])
      _test("/test/test2/test3/",       m, ["var": "test", "var2": "test2", "pathRest": "test3"])
      _test("/test/test2/test3/test4",  m, ["var": "test", "var2": "test2", "pathRest": "test3/test4"])
      _test("/test/test2/test3/test4/", m, ["var": "test", "var2": "test2", "pathRest": "test3/test4"])
    }
    
    ["/{var}/test2", "/{var}/test2/"].each {
      m := Matcher.fromStr(it)
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",        m, ["var": "test"])
      _test("/test/test2/",       m, ["var": "test"])
      _test("/test/test",         m, null)
      _test("/test/test/",        m, null)
      _test("/test/test2a",       m, null)
      _test("/test/test2/test3",  m, null)
      _test("/test/test2/test3/", m, null)
    }
    
    ["/{var}/test2/{var3}", "/{var}/test2/{var3}/"].each {
      m := Matcher.fromStr(it)
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",        m, null)
      _test("/test/test2/",       m, null)
      _test("/test/test/test3",   m, null)
      _test("/test/test/test3/",  m, null)
      _test("/test/test2a/test3", m, null)
      _test("/test/test2/test3",  m, ["var": "test", "var3": "test3"])
      _test("/test/test2/test3/", m, ["var": "test", "var3": "test3"])
      _test("/test/test2/test3/test4",  m, null)
      _test("/test/test2/test3/test4/", m, null)
    }
    
    ["/test/*", "/test/*/"].each {
      m := Matcher.fromStr(it)
      _test("/",                  m, null)
      _test("/test",              m, ["pathRest": ""])
      _test("/test/",             m, ["pathRest": ""])
      _test("/test2",             m, null)
      _test("/test2/",            m, null)
      _test("/test/test2",        m, ["pathRest": "test2"])
      _test("/test/test2/",       m, ["pathRest": "test2"])
      _test("/test/test2/test3",  m, ["pathRest": "test2/test3"])
      _test("/test/test2/test3/", m, ["pathRest": "test2/test3"])
    }
    
    ["/test/{var}", "/test/{var}/"].each {
      m := Matcher.fromStr(it)    
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",        m, ["var": "test2"])
      _test("/test/test2/",       m, ["var": "test2"])
      _test("/test/test2/test3",  m, null)
      _test("/test/test2/test3/", m, null)    
    }
    
    ["/test/{var2}/*", "/test/{var2}/*/"].each {
      m := Matcher.fromStr(it)    
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",              m, ["var2": "test2", "pathRest": ""])
      _test("/test/test2/",             m, ["var2": "test2", "pathRest": ""])
      _test("/test/test2/test3",        m, ["var2": "test2", "pathRest": "test3"])
      _test("/test/test2/test3/",       m, ["var2": "test2", "pathRest": "test3"])
      _test("/test/test2/test3/test4",  m, ["var2": "test2", "pathRest": "test3/test4"])
      _test("/test/test2/test3/test4/", m, ["var2": "test2", "pathRest": "test3/test4"])    
    }
    
    ["/test/{var2}/{var3}", "/test/{var2}/{var3}/"].each {
      m := Matcher.fromStr(it)    
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",              m, null)
      _test("/test/test2/",             m, null)
      _test("/test/test2/test3",        m, ["var2": "test2", "var3": "test3"])
      _test("/test/test2/test3/",       m, ["var2": "test2", "var3": "test3"])
      _test("/test/test2/test3/test4",  m, null)
      _test("/test/test2/test3/test4/", m, null)    
    }
    
    ["/test/{var2}/test3", "/test/{var2}/test3/"].each {
      m := Matcher.fromStr(it)    
      _test("/",                  m, null)
      _test("/test",              m, null)
      _test("/test/",             m, null)
      _test("/test/test2",              m, null)
      _test("/test/test2/",             m, null)
      _test("/test/test2/test3",        m, ["var2": "test2"])
      _test("/test/test2/test3/",       m, ["var2": "test2"])
      _test("/test/test2/test",         m, null)
      _test("/test/test2/test/",        m, null)
      _test("/test2/test2/test3",       m, null)
      _test("/test2/test2/test3/",      m, null)
      _test("/test/test2/test3/test4",  m, null)
      _test("/test/test2/test3/test4/", m, null)    
    }
    
    m := Matcher.fromStr("/var2/{var2}/var2/")
    _test("/var2/test/var2/", m, ["var2": "test"])
    _test("/var2/var2/var2/", m, ["var2": "var2"])
  }
  
  Void testCustomRegexes() {
    m := Matcher.fromStr("/object/{id:[0-9]+}/create")
    _test("/",                      m, null)
    _test("/object",                m, null)
    _test("/object/str",            m, null)
    _test("/object/123",            m, null)
    _test("/object/123str/create",  m, null)
    _test("/object/str123/create",  m, null)
    _test("/object/123/create",     m, ["id": "123"])
    _test("/object/str/create/tab", m, null)
    _test("/object/123str/create/tab", m, null)
  }
  
  Void testErrorReporting() {
    // '*' not at the end 
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/*/create") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/*/{var}/") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/{var}/*/{var2}/") }
    
    // duplicate '*'
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/*/*") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/test/*/*") }

    // duplicate var name
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/{var}/test/{var}/") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/{var}/{var2}/{var}/") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/{var}/{var2}/{var}/{var2}/var2") }
    
    // var captures not the whole segment
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/smth{var}/") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/test/smth{var}/") }
    
    // 'pathRest' is not a reserved param name
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/{pathRest}/") }
    verifyErr(InvalidPatternErr#) { Matcher.fromStr("/{var}/{pathRest}/{var2}") }
  }
}
