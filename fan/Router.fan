using web

const class InvalidPatternErr : Err {
  new make(Str pattern, Str msg := "", Err? cause := null) 
    : super.make("Cannot parse urlpattern '$pattern': $msg", cause) {}
}

const class Pathterm {
  const static Regex var := Regex <|\{([^:]*)\:?([^:]*)?\}|>
  const static Regex anystr := Regex <|[^/]+|>
  const Regex regex
  const Str? name := null
  new make(Str str) {
    m := var.matcher(str)
    if (!m.matches)
      regex = Regex.fromStr(str)
    else {
      this.name = m.group(1)
      if (m.group(2) != null && m.group(2) != "")
        regex = Regex.fromStr(m.group(2))
      else
        regex = anystr
    }
  }
  
  Bool matches(Str str) {
    regex.matches(str)
  }
  
  override Str toStr() {
    return name == null ? regex.toStr : "{$name:" + regex.toStr + "}"
  }
}

const class UrlMatcher {
  static const Str PATH_TAIL_PARAM := "pathTail" 
  
  const Pathterm[] pathterms
  const Bool freeTail
  new make(Pathterm[] pathterms, Bool freeTail) {
    this.pathterms = pathterms
    this.freeTail = freeTail
  }
  
  static UrlMatcher fromStr(Str pattern) {
    Str[] segments := pattern.split('/').exclude { it == "" }
    freeTail := segments.size >= 1 && segments[-1] == "*"
    if (segments.size >= 2)
      segments[0..-2].each {
        if (it == "*")
          if (freeTail)
            throw InvalidPatternErr(pattern, "There may be only one '*' segment at the end of the pattern")
          else
            throw InvalidPatternErr(pattern, "'*' may only be present as the last pathterm in pattern")
      }
    
    Pathterm[] pathterms := segments.exclude { it == "*" }.map |segment| {
      Pathterm? pt
      try {
        pt = Pathterm.make(segment)
      } catch(Err e) {
        throw InvalidPatternErr.make(pattern, "Incorrect segment syntax '$segment'", e)
      }
      if (pt.name == PATH_TAIL_PARAM)
        throw InvalidPatternErr.make(pattern, "'$PATH_TAIL_PARAM' is reserved param name for '*' pathterm")
      return pt
    }
    
    // checking for duplicate names
    varNames := pathterms.map { it.name }.exclude { it == null }
    duplicateVars := Util.duplicates(varNames)
    if (duplicateVars.size == 1)
      throw InvalidPatternErr(pattern, "Duplicate variable '" + duplicateVars.first + "'")
    else if (duplicateVars.size > 1)
      throw InvalidPatternErr(pattern, "Duplicate variables '" + duplicateVars.join("', '") + "'")
    
    return UrlMatcher(pathterms, freeTail)
  }
  
  virtual [Str:Str]? match(Str[] path) {
    if (!this.freeTail && path.size != pathterms.size)
      return null
    
    res := Str:Str[:]
    all := pathterms.all |pathterm, i| {
      if (i < path.size && pathterm.matches(path[i])) {
        if (pathterm.name != null)
          res[pathterm.name] = path[i]
        return true
      }
      return false
    }
    if (all && this.freeTail)
      res[PATH_TAIL_PARAM] = path.size == pathterms.size ? "" : path[pathterms.size..-1].join("/")
    return all ? res : null
  }
  
  override Str toStr() {
    "/" + pathterms.map { it.toStr }.join("/") + (this.freeTail ? "/*" : "") + ""
  }
}

class UrlMatcherTurtle : Turtle {
  UrlMatcher matcher
  Turtle? child
  
  new make(UrlMatcher matcher, Turtle? child := null) { this.matcher = matcher; this.child = child }
  
  override Res? dispatch(Req req) {
    [Str:Str]? match := matcher.match(req.pathInfo.path)
    if (match == null)
      return null
    populateContext(match, req)
    return child.dispatch(req)
  }
  
  virtual Void populateContext([Str:Str] match, Req req) {
    req.context.addAll(match)
  }
}

class Router : Turtle {
  Turtle[] _routes := [,]

  new make(|This| f) { f.call(this) }

  virtual Turtle asRoute(Obj route) { route is Str ? any(route) : route as Turtle }
  
  virtual Turtle? asView(Obj target) {
    if (target is Turtle)
      return target
    else if (target is Func)
      return FuncView { func = target }
    else if (target is Method) {
      m := target as Method
      if (m.isStatic)
        return FuncView { func = m.func }
      else
        return MethodView(m)
    } 
    return null
  }
  
  virtual Turtle any(Str path) { UrlMatcherTurtle(UrlMatcher(path)) }
  
  virtual Void routes(Obj[][] arg) { arg.each { Router#bind.func.callOn(this, it) } }
  
  virtual Void bind(Obj route, Obj target) {
    route = asRoute(route)
    route->child = asView(target)
    _routes.add(route)
  }
  
  override Res? dispatch(Req req) { return _routes.eachWhile { it.dispatch(req) } }
}