
using web

class HttpRes {
  virtual Str:Str headers := [:]
  internal virtual Int statusCode
  internal virtual Obj body 
  internal virtual Charset charset := App.instance.charset
  
  new make(Obj content := "", Int status := 200, Str? contentType := "text/html") {
    this.body = content
    this.statusCode = status
    if (contentType != null)
      this.headers["Content-Type"] = "$contentType; charset=$this.charset"
  }
  
  Void writeBody(OutStream out) {
    if (body is InStream)
      (body as InStream).pipe(out)
    else if (body is File)
      (body as File).in.pipe(out, (body as File).size)
    else if (body is List)
      (body as List).each { out.writeChars(it == null ? "null" : it.toStr) }
    else
      out.writeChars(body.toStr)
  }
}

class HttpResRedirect : HttpRes {
  new make(Uri redirectTo) : super("", 302) {
    headers["Location"] = redirectTo.encode
  }
}

class HttpResPermanentRedirect : HttpRes {
  new make(Uri redirectTo) : super("", 301) {
    headers["Location"] = redirectTo.encode
  }
}

class HttpResNotModified : HttpRes {
  new make() : super("", 304) {}
}

class HttpResBadRequest : HttpRes {
  new make() : super("", 400) {}
}

class HttpResNotFound : HttpRes {
  new make(Obj content := "") : super(content, 404) {}
}

class HttpResForbidden : HttpRes {
  new make() : super("", 403) {}
}

class HttpResNotAllowed : HttpRes {
  new make(Str[] permittedMethods) : super("", 405) {
    headers["Allow"] = permittedMethods.join(", ")
  }
}

class HttpResGone : HttpRes {
  new make(Obj content := "", Int status := 410, Str? contentType := "text/html") : super(content, status, contentType) {}
}

class HttpResServerError : HttpRes {
  new make(Obj content := "", Int status := 500, Str? contentType := "text/html") : super(content, status, contentType) {}
}