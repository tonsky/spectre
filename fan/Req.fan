
using web

abstract class Req {
  const static Log log := WatchPodActor#.pod.log

  ** Map of arbitrary values usually populated by `Middleware`s to prepare values for views. 
  ** All values presented in `#context` can be used as view arguments (resolved by name).
  ** This slot and its value are both readonly. See `#dupWith`.
  readonly Str:Obj? context := [:].ro
  
  ** Returns a copy of current `Req` with values in context 
  ** set (added or overriden) with 'overrde' parameter values.
  Req dupWith(Str:Obj? overrde) { ReqWrapper(this) { it.context = this.context.dup.setAll(overrde) } }
  
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
  
  ** HTTP request method ('"get"' or '"post"' or another).
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
    cookies.each { result.add(it.name, it.val) }
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
}