
using web

abstract class Req {
  const static Log log := Log.get("spectre")

  ** Map of arbitrary values usually populated by `Middleware`s to prepare values for views. 
  ** All values presented in `#context` can be used as view arguments (resolved by name).
  ** This slot and its value are both readonly. See `#dup`.
  internal Str:Obj? _context := ["req": this].ro
  internal abstract Settings? app()
  
  ** Resolve injectible data stored in `Req#context` or `Req#app` slots or `Req` itself, by name.
  Obj? context(Str name, Bool raiseErr := true, Obj? def := null) {
    if (_context.containsKey(name)) return _context[name]
    if (TypeUtil.supports(app, name)) return app.trap(name)
    if (raiseErr) throw ArgErr("Cannot resolve ‘$name’, options are: $_context + app slots: " 
      + app.typeof.slots.findAll { it.isField || (it.isMethod && (it as Method).params.size == 0)}.map { name } )
    else return def
  }
  
  ** Returns a copy of current `Req` with values in context added or overriden. See `Req#context`.
  Req dup(Str:Obj? overrde) { 
    overrde.isEmpty ? this : (ReqWrapper(this) { it._context = this._context.dup.set("req", it).setAll(overrde).ro })
  }
  
  ** Current request’s GET arguments.
  abstract QueryMap get()
  
  ** Current request’s POST arguments.
  abstract QueryMap post()
  
  ** Values from both `#get` and `#post` combined in a single `QueryMap`.
  ** If value exists in both `#get` and `#post`, value from `#post` is used.
  abstract QueryMap request()
  
  ** `Uri` of current http request.
  abstract Uri pathInfo()
  
  ** HTTP request headers
  abstract Str:Str headers()
  
  ** HTTP request method ('"GET"' or '"POST"' or another).
  abstract Str method()
  
  ** Raw HTTP request input stream.
  abstract InStream in()
  
  ** Current browser session’s cookies. They’re for reading only, to set cookie, use `Res.setCookie`.
  virtual once [Str:Str] cookies() {
    Str? cookieHeader := headers["Cookie"]
    if (cookieHeader == null)
      return [:]
    
    [Str:Str] result := [:]
    cookies := spectre::Cookie.load(cookieHeader)
    cookies.each { if (!result.containsKey(it.name)) result.add(it.name, it.val) }
    return result.toImmutable
  }
}

internal class ReqWrapper : Req {
  private Req impl

  new make(Req req, |This| f) {
    this.impl = req
    f.call(this)
  }
  
  override QueryMap get() { impl.get }
  override QueryMap post() { impl.post }
  override QueryMap request() { impl.request }
  
  override Uri pathInfo() { impl.pathInfo }
  override Str:Str headers() { impl.headers }
  override Str method() { impl.method }
  
  override InStream in() { impl.in }
  internal override Settings? app() { impl.app }
}