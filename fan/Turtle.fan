
**
** A unit of request processing hierarchy
** 
mixin Turtle {
  abstract Res? dispatch(Req req)
}

**
** Returns first not-null result obtained from children 
** 
class Selector : Turtle {
  Turtle[] children := [,]

  **
  ** This class accepts Turtles only, but children may support other argument types
  ** 
  virtual This add(Obj obj) {
    if (obj is Turtle)
      children.add(obj)
    else
      throw ArgErr("${obj.typeof} cannot be added, Turtle required")
    return this
  }
  
  override Res? dispatch(Req req) { return children.eachWhile { it.dispatch(req) } }
}

**
** Base class for middlewares: a turtles that wrap another turtle (`child`),
** and do something before and/or after child's dispatch.
** 
abstract class Middleware : Turtle {
  Turtle? child

  virtual This wrap(Turtle child) { this.child = child; return this }
  
  override Res? dispatch(Req req) {
    before(req)
    Res? res := child.dispatch(req)
    return after(req, res)
  }
  
  virtual Void before(Req req) {}
  virtual Res? after(Req req, Res? res) { 
    return res == null ? null : safeAfter(req, res)
  }
  virtual Res? safeAfter(Req req, Res res) { return res }
}

**
** Exception to stop everything and bubble up to `Handler404` 
** 
const class Http404 : Err {
  new make(Str msg) : super.make(msg) {}
}

**
** `Http404` error barrier, catch `Http404` and render error message to `Res`
** 
class Handler404 : Middleware {
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

**
** Top-level error barrier, catch any `Err` and render error message to `Res`
** 
class Handler500 : Middleware {
  override Res? dispatch(Req req) {
    try {
      return child.dispatch(req)
    } catch (Err err) {
      return dispatchErr(err)
    }
  }
  
  virtual Res? dispatchErr(Err err) {
    return ResServerError.make("<h1>500 Internal server error</h1>"
                             + "<pre>${Util.traceToStr(err)}</pre>")
  }
  //TODO implement virtual get/renderTemplate
}