
using web

abstract class Req {
  const static Log log := WatchPodActor#.pod.log
  [Str:Obj?] context := [:]
  
  abstract QueryMap get()
  abstract QueryMap post()
  abstract QueryMap request()
  
  abstract Uri pathInfo()
  abstract Str:Str headers()
  abstract Str method()
  
  abstract InStream in()
  
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
