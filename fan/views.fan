
using web
using mustache

mixin View {

  ** Used in error reporting
  abstract Obj caller
  
  virtual Obj? tryMake(Type type, Req req) {
    constructor := type.method("make").func
    return tryCall(constructor, req)
  }
  
  virtual Obj? tryMethodCall(Method method, Obj instance, Req req) {
    func := method.func.bind([instance])
    paramValues := resolveParamValues(func.params, req)
    return func.callList(paramValues)
  }
  
  virtual Obj? tryCall(Func func, Req req) {
    paramValues := resolveParamValues(func.params, req)
    return func.callList(paramValues)
  }
  
  virtual Obj?[] resolveParamValues(Param[] params, Req req) {
    Obj?[] paramValues := [,]
    Param? defaultUsed := null
    
    for (idx := 0; idx < params.size; ++idx) {
      Param param := params[idx]
      if(paramHasValue(param, req)) {
        if (defaultUsed != null)
          throw ArgErr("Param '$param.name' cannot be set because '$defaultUsed.name'"
                     + " is using default value before him, in $caller")
        
        paramValues.add(resolveParamValue(param, req))
      } else {
        if (param.hasDefault)
          defaultUsed = param
        else
          throw ArgErr("Unmatched action param '$param.name' in $caller
                        matches are ${req.context}")
      }
    }
    
    return paramValues
  }
  
  virtual Bool paramHasValue(Param param, Req req) {
    return param.type == Req# || req.context.containsKey(param.name)
  }
  
  virtual Obj? resolveParamValue(Param param, Req req) {
    if (param.type == Req#)
      return req
      
    if (req.context.containsKey(param.name)) {
      Str paramStr := req.context[param.name]
      return param.type == Str# ? paramStr : param.type.method("fromStr").call(paramStr)
    }
    
    throw ArgErr("Unmatched action param '$param.name' in $caller
                  matches are ${req.context}")
  }
}

class MethodView : View, Turtle {
  Method method
  override Obj caller { get { method } }
  
  new make(Method method) { this.method = method }
  
  override Res? dispatch(Req req) {
    instance := tryMake(method.parent, req)
    return tryMethodCall(method, instance, req)
  }
}

class FuncView : View, Turtle {
  Func? func
  override Obj caller { get { func } }
  
  override Res? dispatch(Req req) {
    return tryCall(func, req)
  }
}



const class Http404 : Err {
  new make(Str msg) : super.make(msg) {}
}

class Handler404 : Turtle {
  Turtle? child
  
  override Res? dispatch(Req req) {
    try {
      return child.dispatch(req) ?: dispatchEmptyResponse(req)
    } catch (Http404 err) {
      return dispatch404(req, err)
    }    
  }
  
  virtual Res? dispatchEmptyResponse(Req req) {
    return dispatch404(req)
  }
  
  virtual Res? dispatch404(Req req, Http404? err := null) {
    return ResNotFound.make("<h1>404 Not found</h1><strong>Requested:</strong><br/>"
      + "<pre>$req.pathInfo</pre><br/>"
      + (err == null ? "Empty response" : "<pre>${err.msg}:${err.traceToStr}</pre>")
      //FIXME output existing routes
//      +"<br/><strong>Tried:</strong><br/><pre>" 
//      + tried.map { it.toStr }.join("\n") + "</pre>"
      )
  }
  
  //TODO implement virtual get/renderTemplate
}

class Handler500 : Turtle {
  Turtle? child
  
  override Res? dispatch(Req req) {
    try {
      return child.dispatch(req)
    } catch (Err err) {
      return dispatchErr(err)
    }
  }
  
  virtual Res? dispatchErr(Err err) {
    return ResServerError.make("<h1>500 Internal server error</h1>"
                             + "<pre>$err.traceToStr</pre>")
  }
  //TODO implement virtual get/renderTemplate
}


class StaticView : Turtle {
  File staticDir
  new make(File staticDir) {
    this.staticDir = staticDir
  }
  
  virtual DateTime modified(File file) {
    return file.modified.floor(1sec)
  }

  virtual Str etag(File file) {
    return "\"" + file.size.toHex + "-" + file.modified.ticks.toHex + "\""
  }

  override Res? dispatch(Req req) {
    pathRest := req.context[UrlMatcher.PATH_TAIL_PARAM]
    file := staticDir + Uri.fromStr(pathRest)
    
    // if file doesn't exist
    if (!file.exists) {
      return Res("File not found: $file", 404)
    }

    if (checkNotModified(req, file))
      return Res("", 304)
    
    response := Res(file, 200, file.mimeType?.toStr ?: "")
    
    // set identity headers
    response.headers["ETag"] = etag(file)
    response.headers["Last-Modified"] = modified(file).toHttpStr
    response.headers["Content-Length"] = file.size.toStr
    
    return response
  }

  **
  ** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
  **
  virtual protected Bool checkNotModified(Req req, File file) {
    // check If-Match-None
    matchNone := req.headers["If-None-Match"]
    if (matchNone != null) {
      etag := this.etag(file)
      match := WebUtil.parseList(matchNone).any |Str s->Bool| {
        return s == etag || s == "*"
      }
      if (match)
        return true
    }

    // check If-Modified-Since
    since := req.headers["If-Modified-Since"]
    if (since != null) {
      sinceTime := DateTime.fromHttpStr(since, false)
      if (modified(file) == sinceTime)
        return true
    }

    // gotta do it the hard way
    return false
  }
}