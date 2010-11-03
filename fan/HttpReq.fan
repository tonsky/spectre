
using web

abstract class HttpReq {
  const static Log log := WatchPodActor#.pod.log
  
  abstract QueryMap get()
  abstract QueryMap post()
  abstract QueryMap request()
  
  abstract Uri pathInfo()
  abstract Str:Str headers()
  abstract Str method()
  
  abstract InStream in()
}
