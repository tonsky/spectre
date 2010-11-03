
using web
using mustache

const class Http404 : Err {
  new make(Str msg) : super.make(msg) {}
}

class Handler500 {
  Err err
  new make(Err err): super() {
    this.err = err
  }
  
  HttpRes dispatch() {
    HttpResServerError.make("<h1>500 Internal server error</h1>"
      +"<pre>$err.traceToStr</pre>")
  }
}

class Handler404 {
  Matcher[] tried
  new make(Matcher[] tried) {
    this.tried = tried
  }
  
  HttpRes dispatch(HttpReq req) {
    HttpResNotFound.make("<h1>404 Not found</h1><strong>Requested:</strong><br/>"
      +"<pre>$req.pathInfo</pre><br/><strong>Tried:</strong><br/><pre>" 
      + tried.map { it.toStr }.join("\n") + "</pre>")
  }
}

class StaticController {
  File staticDir
  new make(File staticDir) {
    this.staticDir = staticDir
  }
  
  virtual DateTime modified(File file) {
    return file.modified.floor(1sec)
  }

  virtual Str etag(File file) {
    return "\"" + file.size.toHex + "-" + file.modified.ticks.toHex + "\""
  }

  virtual HttpRes dispatch(HttpReq req, Str pathRest) {
    file := staticDir + Uri.fromStr(pathRest)
    
    // if file doesn't exist
    if (!file.exists) {
      return HttpRes.make("File not found: $file", 404)
    }

    if (checkNotModified(req, file))
      return HttpRes.make("", 304)
    
    response := HttpRes.make(file, 200, file.mimeType?.toStr ?: "")
    
    // set identity headers
    response.headers["ETag"] = etag(file)
    response.headers["Last-Modified"] = modified(file).toHttpStr
    response.headers["Content-Length"] = file.size.toStr
    
    return response
  }

  **
  ** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
  **
  virtual protected Bool checkNotModified(HttpReq req, File file) {
    // check If-Match-None
    matchNone := req.headers["If-None-Match"]
    if (matchNone != null) {
      etag := this.etag(file)
      match := WebUtil.parseList(matchNone).any |Str s->Bool| {
        return s == etag || s == "*"
      }
      if (match)
        return true
    }

    // check If-Modified-Since
    since := req.headers["If-Modified-Since"]
    if (since != null) {
      sinceTime := DateTime.fromHttpStr(since, false)
      if (modified(file) == sinceTime)
        return true
    }

    // gotta do it the hard way
    return false
  }
}