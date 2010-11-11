
using web

abstract class Req {
  const static Log log := WatchPodActor#.pod.log
  [Str:Str] context := [:]
  
  abstract QueryMap get()
  abstract QueryMap post()
  abstract QueryMap request()
  
  abstract Uri pathInfo()
  abstract Str:Str headers()
  abstract Str method()
  
  abstract InStream in()
}
