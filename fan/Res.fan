
using web

class Res {
  virtual Str:Str headers := [:]
  internal virtual Int statusCode
  internal virtual Obj body 
  internal virtual Charset charset := Settings.instance.charset
  
  new make(Obj content := "", Int status := 200, Str? contentType := "text/html") {
    this.body = content
    this.statusCode = status
    if (contentType != null)
      this.headers["Content-Type"] = "$contentType; charset=$this.charset"
  }
  
  // FIXME hmm
  Void beforeWrite() {
    if (body is File)
      headers["Content-Length"] = (body as File).size.toStr
  }
  
  Void writeBody(OutStream out) {
    if (body is InStream)
      (body as InStream).pipe(out)
    else if (body is File) {
      (body as File).in.pipe(out, (body as File).size)
    } else if (body is List)
      (body as List).each { out.writeChars(it == null ? "null" : it.toStr) }
    else
      out.writeChars(body.toStr)
  }
}

class ResRedirect : Res {
  new make(Uri redirectTo) : super("", 302) {
    headers["Location"] = redirectTo.encode
  }
}

class ResPermanentRedirect : Res {
  new make(Uri redirectTo) : super("", 301) {
    headers["Location"] = redirectTo.encode
  }
}

class ResNotModified : Res {
  new make() : super("", 304) {}
}

class ResBadRequest : Res {
  new make() : super("", 400) {}
}

class ResNotFound : Res {
  new make(Obj content := "") : super(content, 404) {}
}

class ResForbidden : Res {
  new make() : super("", 403) {}
}

class ResNotAllowed : Res {
  new make(Str[] permittedMethods) : super("", 405) {
    headers["Allow"] = permittedMethods.join(", ")
  }
}

class ResGone : Res {
  new make(Obj content := "", Int status := 410, Str? contentType := "text/html") : super(content, status, contentType) {}
}

class ResServerError : Res {
  new make(Obj content := "", Int status := 500, Str? contentType := "text/html") : super(content, status, contentType) {}
}