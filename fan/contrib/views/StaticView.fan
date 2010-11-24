
class StaticView : Turtle {
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

  override Res? dispatch(Req req) {
    pathRest := req.context[UrlMatcher.PATH_TAIL_PARAM]
    file := staticDir + Uri.fromStr(pathRest)
    
    // if file doesn't exist
    if (!file.exists) {
      return Res("File not found: $file", ["statusCode" : 404])
    }

    //FIXME investigate this bug in safari
//    if (checkNotModified(req, file))
//      return Res("", 304)
    
    response := Res(file, ["contentType" : file.mimeType?.toStr ?: ""])
    
    // set identity headers
    response.headers["ETag"] = etag(file)
    response.headers["Last-Modified"] = modified(file).toHttpStr
    response.headers["Content-Length"] = file.size.toStr
    
    return response
  }

  ** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
  virtual protected Bool checkNotModified(Req req, File file) {
    // check If-Match-None
    matchNone := req.headers["If-None-Match"]
    if (matchNone != null) {
      etag := this.etag(file)
      match := web::WebUtil.parseList(matchNone).any |Str s->Bool| {
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