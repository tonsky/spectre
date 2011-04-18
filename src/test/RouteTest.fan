
class RouterTest : Test
{
  private Void _test(Uri uri, UrlMatcher m, [Str:Str]? expected) {
    matchResult := m.match(uri.path)
    verifyEq(expected, matchResult, "Got: $matchResult, expected: $expected on matching '$uri' against $m")
  }
  
  Void testSimpleMatches() {
    m := UrlMatcher("/")
    _test(`/`,       m, Str:Str[:])
    _test(`/test`,   m, null)
    _test(`/test/`,  m, null)
    _test(`/test2`,  m, null)
    _test(`/test2/`, m, null)

    ["/test", "/test/"].each {
      m = UrlMatcher(it)
      _test(`/`,            m, null)
      _test(`/test`,        m, Str:Str[:])
      _test(`/test/`,       m, Str:Str[:])
      _test(`/test/test2`,  m, null)
      _test(`/test/test2/`, m, null)
    }

    ["/test/test2", "/test/test2/"].each {
      m = UrlMatcher(it)
      _test(`/`,            m, null)
      _test(`/test`,        m, null)
      _test(`/test/`,       m, null)
      _test(`/test/test2`,  m, Str:Str[:])
      _test(`/test/test2/`, m, Str:Str[:])
    }
  }
  
  Void testVariableCapturing() {
    ["/*", "/*/"].each {
      m := UrlMatcher(it)
      _test(`/`,            m, [UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test`,        m, [UrlMatcher.PATH_TAIL_PARAM: "test"])
      _test(`/test/`,       m, [UrlMatcher.PATH_TAIL_PARAM: "test"])
      _test(`/test/test2`,  m, [UrlMatcher.PATH_TAIL_PARAM: "test/test2"])
      _test(`/test/test2/`, m, [UrlMatcher.PATH_TAIL_PARAM: "test/test2"])
    }
    
    ["/{var}", "/{var}/"].each {
      m := UrlMatcher(it)
      _test(`/`,            m, null)
      _test(`/test`,        m, ["var": "test"])
      _test(`/test/`,       m, ["var": "test"])
      _test(`/test/test2`,  m, null)
      _test(`/test/test2/`, m, null)
    }
    
    ["/{var}/*", "/{var}/*/"].each {
      m := UrlMatcher(it)
      _test(`/`,                  m, null)
      _test(`/test`,              m, ["var": "test", UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/`,             m, ["var": "test", UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/test2`,        m, ["var": "test", UrlMatcher.PATH_TAIL_PARAM: "test2"])
      _test(`/test/test2/`,       m, ["var": "test", UrlMatcher.PATH_TAIL_PARAM: "test2"])
      _test(`/test/test2/test3`,  m, ["var": "test", UrlMatcher.PATH_TAIL_PARAM: "test2/test3"])
      _test(`/test/test2/test3/`, m, ["var": "test", UrlMatcher.PATH_TAIL_PARAM: "test2/test3"])
    }
    
    ["/{var}/{var2}", "/{var}/{var2}/"].each {
      m := UrlMatcher(it)
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,        m, ["var": "test", "var2": "test2"])
      _test(`/test/test2/`,       m, ["var": "test", "var2": "test2"])
      _test(`/test/test2/test3`,  m, null)
      _test(`/test/test2/test3/`, m, null)
    }
    
    ["/{var}/{var2}/*", "/{var}/{var2}/*/"].each {
      m := UrlMatcher(it)
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,              m, ["var": "test", "var2": "test2", UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/test2/`,             m, ["var": "test", "var2": "test2", UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/test2/test3`,        m, ["var": "test", "var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3"])
      _test(`/test/test2/test3/`,       m, ["var": "test", "var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3"])
      _test(`/test/test2/test3/test4`,  m, ["var": "test", "var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3/test4"])
      _test(`/test/test2/test3/test4/`, m, ["var": "test", "var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3/test4"])
    }
    
    ["/{var}/test2", "/{var}/test2/"].each {
      m := UrlMatcher(it)
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,        m, ["var": "test"])
      _test(`/test/test2/`,       m, ["var": "test"])
      _test(`/test/test`,         m, null)
      _test(`/test/test/`,        m, null)
      _test(`/test/test2a`,       m, null)
      _test(`/test/test2/test3`,  m, null)
      _test(`/test/test2/test3/`, m, null)
    }
    
    ["/{var}/test2/{var3}", "/{var}/test2/{var3}/"].each {
      m := UrlMatcher(it)
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,        m, null)
      _test(`/test/test2/`,       m, null)
      _test(`/test/test/test3`,   m, null)
      _test(`/test/test/test3/`,  m, null)
      _test(`/test/test2a/test3`, m, null)
      _test(`/test/test2/test3`,  m, ["var": "test", "var3": "test3"])
      _test(`/test/test2/test3/`, m, ["var": "test", "var3": "test3"])
      _test(`/test/test2/test3/test4`,  m, null)
      _test(`/test/test2/test3/test4/`, m, null)
    }
    
    ["/test/*", "/test/*/"].each {
      m := UrlMatcher(it)
      _test(`/`,                  m, null)
      _test(`/test`,              m, [UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/`,             m, [UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test2`,             m, null)
      _test(`/test2/`,            m, null)
      _test(`/test/test2`,        m, [UrlMatcher.PATH_TAIL_PARAM: "test2"])
      _test(`/test/test2/`,       m, [UrlMatcher.PATH_TAIL_PARAM: "test2"])
      _test(`/test/test2/test3`,  m, [UrlMatcher.PATH_TAIL_PARAM: "test2/test3"])
      _test(`/test/test2/test3/`, m, [UrlMatcher.PATH_TAIL_PARAM: "test2/test3"])
    }
    
    ["/test/{var}", "/test/{var}/"].each {
      m := UrlMatcher(it)    
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,        m, ["var": "test2"])
      _test(`/test/test2/`,       m, ["var": "test2"])
      _test(`/test/test2/test3`,  m, null)
      _test(`/test/test2/test3/`, m, null)    
    }
    
    ["/test/{var2}/*", "/test/{var2}/*/"].each {
      m := UrlMatcher(it)    
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,              m, ["var2": "test2", UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/test2/`,             m, ["var2": "test2", UrlMatcher.PATH_TAIL_PARAM: ""])
      _test(`/test/test2/test3`,        m, ["var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3"])
      _test(`/test/test2/test3/`,       m, ["var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3"])
      _test(`/test/test2/test3/test4`,  m, ["var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3/test4"])
      _test(`/test/test2/test3/test4/`, m, ["var2": "test2", UrlMatcher.PATH_TAIL_PARAM: "test3/test4"])    
    }
    
    ["/test/{var2}/{var3}", "/test/{var2}/{var3}/"].each {
      m := UrlMatcher(it)    
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,              m, null)
      _test(`/test/test2/`,             m, null)
      _test(`/test/test2/test3`,        m, ["var2": "test2", "var3": "test3"])
      _test(`/test/test2/test3/`,       m, ["var2": "test2", "var3": "test3"])
      _test(`/test/test2/test3/test4`,  m, null)
      _test(`/test/test2/test3/test4/`, m, null)    
    }
    
    ["/test/{var2}/test3", "/test/{var2}/test3/"].each {
      m := UrlMatcher(it)    
      _test(`/`,                  m, null)
      _test(`/test`,              m, null)
      _test(`/test/`,             m, null)
      _test(`/test/test2`,              m, null)
      _test(`/test/test2/`,             m, null)
      _test(`/test/test2/test3`,        m, ["var2": "test2"])
      _test(`/test/test2/test3/`,       m, ["var2": "test2"])
      _test(`/test/test2/test`,         m, null)
      _test(`/test/test2/test/`,        m, null)
      _test(`/test2/test2/test3`,       m, null)
      _test(`/test2/test2/test3/`,      m, null)
      _test(`/test/test2/test3/test4`,  m, null)
      _test(`/test/test2/test3/test4/`, m, null)    
    }
    
    m := UrlMatcher("/var2/{var2}/var2/")
    _test(`/var2/test/var2/`, m, ["var2": "test"])
    _test(`/var2/var2/var2/`, m, ["var2": "var2"])
  }
  
  Void testCustomRegexes() {
    m := UrlMatcher("/object/{id:[0-9]+}/create")
    _test(`/`,                      m, null)
    _test(`/object`,                m, null)
    _test(`/object/str`,            m, null)
    _test(`/object/123`,            m, null)
    _test(`/object/123str/create`,  m, null)
    _test(`/object/str123/create`,  m, null)
    _test(`/object/123/create`,     m, ["id": "123"])
    _test(`/object/str/create/tab`, m, null)
    _test(`/object/123str/create/tab`, m, null)
  }
  
  Void testErrorReporting() {
    // '*' not at the end 
    verifyErr(InvalidPatternErr#) { UrlMatcher("/*/create") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/*/{var}/") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/{var}/*/{var2}/") }
    
    // duplicate '*'
    verifyErr(InvalidPatternErr#) { UrlMatcher("/*/*") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/test/*/*") }

    // duplicate var name
    verifyErr(InvalidPatternErr#) { UrlMatcher("/{var}/test/{var}/") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/{var}/{var2}/{var}/") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/{var}/{var2}/{var}/{var2}/var2") }
    
    // var captures not the whole segment
    verifyErr(InvalidPatternErr#) { UrlMatcher("/smth{var}/") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/test/smth{var}/") }
    
    // 'pathRest' is not a reserved param name
    verifyErr(InvalidPatternErr#) { UrlMatcher("/{pathTail}/") }
    verifyErr(InvalidPatternErr#) { UrlMatcher("/{var}/{pathTail}/{var2}") }
  }
}
