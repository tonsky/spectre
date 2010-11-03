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

const class Matcher {
  static const Str FREE_ENDING_PARAM := "pathRest" 
  
  const Pathterm[] pathterms
  const Bool freeEnding
  new make(Pathterm[] pathterms, Bool freeEnding) {
    this.pathterms = pathterms
    this.freeEnding = freeEnding
  }
  
  static Matcher fromStr(Str pattern) {
    Str[] segments := pattern.split('/').exclude { it == "" }
    freeEnding := segments.size >= 1 && segments[-1] == "*"
    if (segments.size >= 2)
      segments[0..-2].each {
        if (it == "*")
          if (freeEnding)
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
      if (pt.name == FREE_ENDING_PARAM)
        throw InvalidPatternErr.make(pattern, "'$FREE_ENDING_PARAM' is not a reserved parameter name for '*' pathterm")
      return pt
    }
    
    // checking for duplicate names
    varNames := pathterms.map { it.name }.exclude { it == null }
    duplicateVars := Util.duplicates(varNames)
    if (duplicateVars.size == 1)
      throw InvalidPatternErr(pattern, "Duplicate variable '" + duplicateVars.first + "'")
    else if (duplicateVars.size > 1)
      throw InvalidPatternErr(pattern, "Duplicate variables '" + duplicateVars.join("', '") + "'")
    
    return Matcher.make(pathterms, freeEnding)
  }
  
  virtual [Str:Str]? match(Str[] path) {
    if (!this.freeEnding && path.size != pathterms.size)
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
    if (all && this.freeEnding)
      res[FREE_ENDING_PARAM] = path.size == pathterms.size ? "" : path[pathterms.size..-1].join("/")
    return all ? res : null
  }
  
  override Str toStr() {
    "/" + pathterms.map { it.toStr }.join("/") + (this.freeEnding ? "/*" : "") + ""
  }
}

const class Binding {
  const Matcher matcher
  const |->Obj| controllerBuilder
  const Str? method
  
  new make(Matcher matcher, |->Obj| controllerBuilder, Str? method) {
    this.matcher = matcher
    this.controllerBuilder = controllerBuilder
    this.method = method
  }
}

mixin Router {
  const static Log log := Router#.pod.log
  abstract Binding[] bindings()

  virtual HttpRes process(HttpReq request) {
    pathStr := request.pathInfo.pathStr
    Str[] path := request.pathInfo.path
    log.info("[REQ] $pathStr")
    
    try {
      b := this.bindings.find |b| { b.matcher.match(path) != null }
      
      if (b != null) {
        Obj controller := b.controllerBuilder.call   
        Str:Str pathParams := b.matcher.match(path)
        return callController(request, controller, b.method, pathParams)      
      } else
        return callController(request, Handler404.make(bindings.map { it.matcher }), "dispatch", [:])
    } catch (Http404 err) {
      return callController(request, Handler404.make(bindings.map { it.matcher }), "dispatch", [:])
    } catch (Err err) {
      return callController(request, Handler500.make(err), "dispatch", [:])
    }
  }
  
  virtual HttpRes callController(HttpReq request, Obj controller, Str? methodName, Str:Str pathParams) {
    method := controller.typeof.method(methodName ?: pathParams["method"])
    if (!method.returns.fits(HttpRes#))
      throw Err.make("Action method must return spectre::Response instead of $method.returns: $controller.typeof.name#$method.name")

    callArgs := method.params.map |param| { 
      Obj? paramValue := pathParams[param.name]
      if (param.type == HttpReq#)
        paramValue = request      
      if (paramValue == null && !param.hasDefault)
        throw Err.make("Unmatched action param '$param.name' in $controller.typeof.name#$method.name
                        matches are $pathParams")
      if (param.type != Str#)
        paramValue = param.type.method("fromStr").call(paramValue)
      return paramValue
    }

    return method.callOn(controller, callArgs)
  }
}