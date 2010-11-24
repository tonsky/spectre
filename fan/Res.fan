
using web

**
** `Res` is your way to tell spectre, what it should send to the client in response 
** to his request. `Res` may be returned by view or any middleware. Moreover, 
** middlewares are allowed to change returned `Res` as they need, or return their 
** own one instead.
** 
** Typical usage is to pass the content of the page to constructor as a `Str`:
** 
**   Res("<h1>Hello world!</h1>")
** 
** You can also pass `InStream`, `File` or `List` (will send merged content of list 
** elements, converted to strings), or any other `Obj` that supports 'toStr()'.
** 

class Res {
  virtual Str:Str headers := [:]
  virtual Int statusCode
  virtual Obj? content
  virtual Charset charset := Settings.instance.charset
  
  **
  ** Supported options:
  **   - "statusCode": Int. Http status code of this response
  **   - "contentType": Str
  **
  new make(Obj? content, Str:Obj options := [:]) {
    this.content = content
    this.statusCode = options.get("statusCode", 200)
    contentType := options.get("contentType", "text/html")
    this.headers["Content-Type"] = "$contentType; charset=$this.charset"
  }
  
  **
  ** A command to set a cookie will be sent to the client in this response. 
  ** Note that setting cookie in `Res` will not automatically made it visible 
  ** in current `Req`.
  **   
  virtual This setCookie(spectre::Cookie cookie) {
    if (headers["Set-Cookie"] == null)
      headers["Set-Cookie"] = cookie.toStr
    else
      headers["Set-Cookie"] = headers["Set-Cookie"] + "," + cookie.toStr
    return this
  }
  
  **
  ** A command for the client to remove cookie will be sent in this response.
  **   
  virtual This deleteCookie(Str cookieName) {
    setCookie(spectre::Cookie {name=cookieName; maxAge = Duration(-1)})
  }

  // FIXME hmm
  virtual Void beforeWrite() {
    if (content is File)
      headers["Content-Length"] = (content as File).size.toStr
  }
  
  virtual Void writeBody(OutStream out) {
    if (content == null)
      out.writeChars("No content")
    else if (content is InStream)
      (content as InStream).pipe(out)
    else if (content is File) {
      (content as File).in.pipe(out, (content as File).size)
    } else if (content is List)
      (content as List).each { out.writeChars(it == null ? "null" : it.toStr) }
    else
      out.writeChars(content.toStr)
  }
}

**
** Issues a 302 redirect (found).
** 
class ResRedirect : Res {
  new make(Uri redirectTo) : super("", ["statusCode": 302]) {
    headers["Location"] = redirectTo.encode
  }
}

**
** Issues a 301 redirect (moved permanently).
** 
class ResPermanentRedirect : Res {
  new make(Uri redirectTo) : super("", ["statusCode": 301]) {
    headers["Location"] = redirectTo.encode
  }
}

**
** Issues a 304 Not Modified response. Use this if page was not modified since 
** last client's request and can be loaded from browser's cache.
** 
class ResNotModified : Res {
  new make() : super("", ["statusCode": 304]) {}
}

**
** Issues a 404 Not Found response. Use this if requested page doesn't exist 
** on your server.
** 
class ResNotFound : Res {
  new make(Obj content := "") : super(content, ["statusCode": 404]) {}
}

**
** Issues a 403 Forbidden response. Client is not authorized to see 
** requested page/run requested operaion.
** 
class ResForbidden : Res {
  new make() : super("", ["statusCode": 403]) {}
}

**
** Issues a 500 Internal Server Error response. The server encountered an 
** unexpected condition which prevented it from fulfilling the request.
** 
class ResServerError : Res {
  new make(Obj content := "", Str:Obj options := [:]) : super(content, options) {
    if (!options.containsKey("statusCode"))
      this.statusCode = 500
  }
}

**
** Issues a 400 Bad Request response. The request could not be understood by 
** the server due to malformed syntax.
** 
class ResBadRequest : Res {
  new make() : super("", ["statusCode": 400]) {}
}

**
** Issues a 405 Method Not Allowed response. The method specified in the request 
** is not allowed for the resource identified by the uri. ``permittedMethods`` 
** should contain list of methods allowed for this resource (e.g. ``["get", "post"]``).
** 
class ResMethodNotAllowed : Res {
  new make(Str[] permittedMethods) : super("", ["statusCode": 405]) {
    headers["Allow"] = permittedMethods.join(", ")
  }
}

**
** Issues a 410 Gone response. The requested resource is no longer available 
** at the server and no forwarding address is known.
** 
class ResGone : Res {
  new make(Obj content := "", Str:Obj options := [:]) : super(content, options) {
    if (!options.containsKey("statusCode"))
      this.statusCode = 410
  }
}