
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
  virtual QueryMap headers := QueryMap()
  virtual Int statusCode
  virtual Obj? content
  virtual Charset charset := Charset.utf8
  
  **
  ** Supported options:
  **   - "statusCode": Int. Http status code of this response
  **   - "contentType": Str
  **
  new make(Obj? content, Str:Obj options := [:]) {
    this.content = content
    this.statusCode = options.get("statusCode", 200)
    if (options.containsKey("contentType")) {
      Str ct := options["contentType"]
      if (!ct.contains("charset"))
        ct = "$ct; charset=$charset"
      this.headers["Content-Type"] = ct
    }
  }
  
  **
  ** A command to set a cookie will be sent to the client in this response. 
  ** Note that setting cookie in `Res` will not automatically made it visible 
  ** in current `Req`.
  **   
  virtual This setCookie(spectre::Cookie cookie) {
    headers.add("Set-Cookie", cookie.toStr)
    return this
  }
  
  **
  ** A command for the client to remove cookie will be sent in this response.
  **   
  virtual This deleteCookie(Str cookieName) {
    setCookie(spectre::Cookie {name=cookieName; maxAge = Duration(-1)})
  }

  **
  ** Return 'true' if there is something to write to output stream, 'false' otherwise
  ** 
  virtual Bool beforeWrite() {
    if (content == null)
      return false
    
    //TODO take a look at performance
    if (content is Str)
      content = (content as Str).toBuf(this.charset)
    
    if (content is File || content is Buf)
      headers["Content-Length"] = content->size.toStr

    return true
  }
  
  virtual Void writeBody(OutStream out) {
    if (content == null)
      return
    else if (content is InStream)
      (content as InStream).pipe(out)
    else if (content is File)
      (content as File).in.pipe(out, (content as File).size)
    else if (content is List)
      (content as List).each { out.writeChars(it == null ? "null" : it.toStr) }
    else if (content is Buf)
      out.writeBuf(content)
    else
      out.print(content)
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
** Issues a 302 redirect (found).
** 
class ResRedirect : Res {
  new make(Uri redirectTo) : super("", ["statusCode": 302]) {
    headers["Location"] = redirectTo.encode
  }
}

**
** Issues a 304 Not Modified response. Use this if page was not modified since 
** last client's request and can be loaded from browser's cache.
** 
** 304 response SHOULD NOT contain message body. See `http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html`.
** 
class ResNotModified : Res {
  new make() : super(null, ["statusCode": 304]) {}
}

**
** Issues a 400 Bad Request response. The request could not be understood by 
** the server due to malformed syntax.
** 
class ResBadRequest : Res {
  new make(Obj? content := "") : super(content, ["statusCode": 400]) {}
}

**
** Issues a 403 Forbidden response. Client is not authorized to see 
** requested page/run requested operaion.
** 
class ResForbidden : Res {
  new make(Obj? content := null) : super(content, ["statusCode": 403]) {}
}

**
** Issues a 404 Not Found response. Use this if requested page doesn't exist 
** on your server.
** 
class ResNotFound : Res {
  new make(Obj content := "Page not found"
    , Str:Obj options := [:]) : super(content, options) {

    if (!options.containsKey("statusCode"))
      this.statusCode = 404
    if (!options.containsKey("contentType"))
      this.headers["Content-Type"] = "text/html; charset=$charset"
  }
}

**
** Issues a 405 Method Not Allowed response. The method specified in the request 
** is not allowed for the resource identified by the uri. ``permittedMethods`` 
** should contain list of methods allowed for this resource (e.g. ``["get", "post"]``).
** 
class ResMethodNotAllowed : Res {
  new make(Str[] permittedMethods, Obj content := "", Str:Obj options := [:]) : super(content, options) {
    headers["Allow"] = permittedMethods.join(", ")
    if (!options.containsKey("statusCode"))
      this.statusCode = 405
  }
}

**
** Issues a 410 Gone response. The requested resource is no longer available 
** at the server and no forwarding address is known.
** 
class ResGone : Res {
  new make(Obj content := "Resource is no longer available", Str:Obj options := [:]) : super(content, options) {
    if (!options.containsKey("statusCode"))
      this.statusCode = 410
  }
}

**
** Issues 415 Unsupported Media Type.
** The server is refusing to service the request because the entity of the 
** request is in a format not supported by the requested resource for the 
** requested method.
**
class ResUnsupportedMediaType : Res {
  new make(Obj content := "Unsupported media type.", Str:Obj options := [:]) : super(content, options) {
    if (!options.containsKey("statusCode"))
      this.statusCode = 415
  }
}

**
** Issues a 500 Internal Server Error response. The server encountered an 
** unexpected condition which prevented it from fulfilling the request.
** 
class ResServerError : Res {
  new make(Obj content := "Internal server error", Str:Obj options := [:]) : super(content, options) {
    if (!options.containsKey("statusCode"))
      this.statusCode = 500
    if (!options.containsKey("contentType"))
      this.headers["Content-Type"] = "text/html; charset=$charset"
  }
}

