
using web

class Response {
  private Int statusCode := 200
  private Obj body := "" 
  Str:Str headers := [:]
  private Charset charset := App.instance.charset
  
  new make(Obj content, Int status := 200, Str? contentType := "text/html") {
    this.body = content
    this.statusCode = status
    if (contentType != null)
      this.headers["Content-Type"] = "$contentType; charset=$this.charset"
  }
  
  Void writeResponse(WebRes res) {
    res.headers.addAll(headers)
    res.statusCode = statusCode
    res.out.charset = charset
    if (body is InStream)
      (body as InStream).pipe(res.out)
    else if (body is File)
      (body as File).in.pipe(res.out, (body as File).size)
    else if (body is List)
      (body as List).each { res.out.w(it) }
    else
      res.out.w(body)
  }
}
