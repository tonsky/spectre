
using web
using concurrent

**
** Descendant of this class is an entry point of web application
** 
abstract class Settings {
  new make(Str:Obj? params) {
    params.each |v,k| { 
      f := Settings#.field(k)
      if (f != null) {
        if (v == null || v.typeof.fits(f.type))
          f.set(this, v)
        else if (v.typeof == Str#)
          f.set(this, TypeUtil.createFromStr(f.type, v))
        else
          throw Err("Cannot assign $v of type $v.typeof to field $f of type $f.type")
      }
    }
    
    renderer = MustacheRenderer([appDir + `templates/`], ["useCache": debug])
  }
  
//////////////////////////////////////////////////////////////////////////
// Settings
//////////////////////////////////////////////////////////////////////////
  
  ** Will be set in `#make` from 'params'.
  ** Use this to set up templateDir relative to appDir, for example.
  virtual File? appDir
  
  virtual Bool debug := true
  
  virtual Middleware handler500 := Handler500()
  virtual Middleware handler404 := Handler404()
  virtual Middleware? renderer
  virtual Middleware[] middlewares := [,]
  virtual Turtle? routes
  
  ** Override this to construct turtles hierarchy all by yourself
  virtual once Turtle? root() {
    if (middlewares.isEmpty)
      renderer.wrap(routes)
    else {
      renderer.wrap(middlewares.first)
      Middleware? prev
      middlewares.each { prev?.wrap(it); prev = it }
      middlewares.last.wrap(routes)
    }
    return handler500.wrap(handler404.wrap(renderer))
  }
  
  
//////////////////////////////////////////////////////////////////////////
// WebSockets
//////////////////////////////////////////////////////////////////////////
  
  ** This method should return `WsProcessor` instance that will process
  ** this WebSocket connection. See `WsActor`.
  virtual WsProcessor? wsProcessor(WsHandshakeReq req) { throw UnsupportedErr() }  
}
