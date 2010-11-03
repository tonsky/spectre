
using web

class WebletRequest : HttpReq, Weblet {
  once override QueryMap get() { QueryMap.decodeQuery(req.uri.queryStr).ro }
  once override QueryMap post() { QueryMap.decodeQuery(form).ro }
  once override QueryMap request() { QueryMap.decodeQuery(req.uri.queryStr).setAllMap(post).ro }

  once override Uri pathInfo() { req.uri }
  once override Str:Str headers() { req.headers.ro }
  once override Str method() { req.method }
  
  override InStream in() { req.in }
  
  virtual protected once Str? form()
  {
    ct := headers.get("Content-Type", "").lower
    if (ct.startsWith("application/x-www-form-urlencoded"))
    {
      len := headers["Content-Length"]
      if (len == null) throw IOErr("Missing Content-Length header")
      return req.in.readLine(len.toInt)
    }
    return null
  }
  
  
}
