using inet

class RequestTest : Test {
  Void testCookieParsing() {
    req := TestReq { headers = ["Cookie": "hostname=sub.a.com; hostname=a.com"] }
    // Check if we using first value from cookie string
    verifyEq("sub.a.com", req.cookies["hostname"])
  }
}


class TestReq : Req {
  override Uri pathInfo := `http://localhost:8080/`
  override Str:Str headers := ["Content-Type": "text/html"]
  Str body := ""
  override Str method := "get"
  
  new make(|This|? f := null) { f?.call(this) }
  
  override Settings? app := null
  
  once override QueryMap get() { return QueryMap.decodeQuery(pathInfo.queryStr).ro }
  once override QueryMap post() { QueryMap.decodeQuery(form).ro }
  once override QueryMap request() { QueryMap.decodeQuery(pathInfo.queryStr).setAllMap(post).ro }
  
  override InStream in() { body.in }
  
  virtual protected once Str? form() {
    ct := headers.get("Content-Type", "").lower
    if (ct.startsWith("application/x-www-form-urlencoded")) {
      len := headers["Content-Length"]
      if (len == null) throw IOErr("Missing Content-Length header")
      return in.readLine(len.toInt)
    }
    return null
  }
}
