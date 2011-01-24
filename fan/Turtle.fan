
**
** A unit of request processing hierarchy
** 
const mixin Turtle {
  abstract Res? dispatch(Req req)

  @Operator
  Turtle plusTurtle(Turtle t) {
    Selector([,].addAll(this is Selector ? this->children : [this])
                .addAll(t    is Selector ? t->children    : [t]))
  }
}

**
** Returns first not-null result obtained from children 
** 
const class Selector : Turtle {
  const Turtle[] children := [,]

  new make(Turtle[] children, |This|? f := null) { this.children = children; f?.call(this) }
  
  override Res? dispatch(Req req) { return children.eachWhile { it.dispatch(req) } }
}

**
** Base class for middlewares: a turtles that wrap another turtle (`child`),
** and do something before and/or after child's dispatch.
** 
abstract const class Middleware : Turtle {
  const Turtle? child
  new make(Turtle child) { this.child = child }
  
  override Res? dispatch(Req req) {
    modifiedReq := before(req)
    Res? res := child.dispatch(modifiedReq)
    return after(modifiedReq, res)
  }
  
  virtual Req before(Req req) { return req }
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
const class Handler404 : Middleware {
  new make(Turtle child, |This|? f := null) : super(child) { f?.call(this) }
  
  override Res? dispatch(Req req) {
    try {
      return child.dispatch(req) ?: dispatchEmptyResponse(req)
    } catch (Http404 err) {
      return dispatch404(req, err)
    }    
  }
  
  virtual Res? dispatchEmptyResponse(Req req) { return dispatch404(req) }
  
  virtual Res? dispatch404(Req req, Http404? err := null) {
    return ResNotFound(
      """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
           "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
         <html>
           <head><title>404 Page not found</title></head>
           <body style="margin: 0; padding: 0"> 
             <h1 style="font: normal 24px sans-serif; padding: 32px 32px 16px; margin: 0; 
                        background-color: #444; color: #FFB266; border-bottom: 1px solid #AAA">
               404 Page not found
             </h1>
             <pre style="margin: 32px; font: 13px/1.5em monospace">
         <strong>Requested:</strong>
         $req.pathInfo"""
         + (err == null ? "" : Util.traceToStr(err)) +
      """</pre>
           </body>
         </html>"""
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
const class Handler500 : Middleware {
  new make(Turtle child, |This|? f := null) : super(child) { f?.call(this) }

  override Res? dispatch(Req req) {
    try {
      return child.dispatch(req)
    } catch (Err err) {
      return dispatchErr(req, err)
    }
  }
  
  virtual Res? dispatchErr(Req req, Err err) {
    return ResServerError(
      """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
           "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
         <html>
           <head><title>$err.msg — 500 Internal server error</title></head>
           <body style="margin: 0; padding: 0"> 
             <h1 style="font: normal 24px sans-serif; padding: 32px 32px 16px; margin: 0; 
                        background-color: #444; color: #FFB266; border-bottom: 1px solid #AAA">
               500 Internal server error
             </h1>
             <pre style="margin: 32px; font: 13px/1.5em monospace">
         ${Util.traceToStr(err)}
             </pre>
           </body>
         </html>""")
  }
  //TODO implement virtual get/renderTemplate
}
