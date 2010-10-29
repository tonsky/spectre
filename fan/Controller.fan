
using web
using mustache


internal const class WebletImpl : Weblet {
}

abstract class Controller {
  private const static WebletImpl webletImpl := WebletImpl.make
  WebReq req() { webletImpl.req }
//  WebRes res() { webletImpl.res }
  
  Str:Str params// { get { &params.ro } }
  
  new make() {
    this.params = req.uri.query.dup
  }
 
//  Void toResponse(Str content,
//                  Int statusCode := 200,
//                  Str contentType := "text/html; charset=utf-8") {
//    res.statusCode = statusCode
//    res.headers["Content-Type"] = contentType
//    res.out.print(content)
//  }
  
}

mixin MustacheTemplates {
  Str renderTemplate(Str templateName,
                     Str:Obj? context := [:],
                     Int statusCode := 200,
                     Str contentType := "text/html; charset=utf-8") {
    Mustache? template := App.instance.loadTemplate(templateName)
    if (template == null)
      throw Err.make("Cannot find template $templateName")
    return template.render(context)
  }
}

//class FuncController : ViewController {
//  Int statusCode
//  |->Str| onServiceFunc
//  
//  new make(Int statusCode, |->Str| func) {
//    this.statusCode = statusCode
//    this.onServiceFunc = func
//  }
//  
//  Void dispatch() {
//    toResponse(onServiceFunc.call, this.statusCode)
//  }
//}

class Handler500 : Controller {
  Err err
  new make(Err err) {
    this.err = err
  }
  
  Response dispatch() {
    Response.make("<pre>" + this.err.traceToStr + "</pre>", 200)
  }
}

class Handler404 : Controller {
  Response dispatch(Matcher[] tried) {
    Response.make("<h1>Route not found</h1>" + req.uri
      + "<hr/>Tried: " + tried.map { it.toStr }.join("<br/>"), 200)
  }
}

class Static : Controller {
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

  virtual Response dispatch(Str pathRest) {
    file := staticDir + Uri.fromStr(pathRest)
    
    // if file doesn't exist
    if (!file.exists) {
      return Response.make("File not found: $file", 404)
    }

    if (checkNotModified(file))
      return Response.make("", 304)
    
    response := Response.make(file, 200, file.mimeType?.toStr ?: "")
    
    // set identity headers
    response.headers["ETag"] = etag(file)
    response.headers["Last-Modified"] = modified(file).toHttpStr
    response.headers["Content-Length"] = file.size.toStr
    
    return response
  }

  **
  ** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
  **
  virtual protected Bool checkNotModified(File file)
  {
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