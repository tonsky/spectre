using inet
using web

class HttpReq {
  static const Version nullVersion := Version("0")
  static const Version ver10 := Version("1.0")
  static const Version ver11 := Version("1.1")
  static const Str:Str nullHeaders := Str:Str[:]
  
  InStream? in { get { &in ?: throw Err("Attempt to access WebReq.in with no content") } }
  virtual Bool isAllRead() { &in == null || &in.peek == null }

  Str method := ""
  Version version := nullVersion
  IpAddr remoteAddr
  Int remotePort
  Str:Str headers := nullHeaders
  Uri uri := ``

  new make(|This|? f := null) { f?.call(this) }
  new makeTest(InStream in) { this.in = in; remoteAddr = IpAddr.local }
  
  override Str toStr() { "$method $uri HTTP/$version\n " + headers.join("\n ") }
}

class HttpRes {
  Int status := 200
  Str[][] headers := [,]
  Obj? body
  new make(Int status, Str[][] headers, Obj? body := null) {
    this.status =  status
    this.headers = headers
    this.body = body
  }
}

const class HttpProtocol : Protocol {
  private static const Log log := HttpProtocol#.pod.log
  static const Str serverVer   := "SpectreDevServer/" + HttpProtocol#.pod.version
  
  const |HttpReq->HttpRes| process
  new make(|HttpReq->HttpRes| process) { this.process = process }

  override Bool onConnection(HttpReq req, TcpSocket socket) {
    in := socket.in
    out := socket.out
    
    HttpReq? _req := req
    while(_req != null) {
      keepAlive := false
      try {
        _req.in = WebUtil.makeContentInStream(_req.headers, in)
        res := process.call(_req)
        keepAlive = writeResponse(res, _req, out)
  
        
        out.flush
        
        // if the listener didn’t finishing reading the content
        // stream then don’t attempt to reuse this connection,
        // safest thing is to just close the socket
        if (!req.isAllRead) {
          keepAlive = false
        }
      } catch (IOErr e) {
        if (log.isDebug)
          log.debug("Error processing request:\n $_req", e)
        keepAlive = false
      } catch(Err e) {
        log.err("Error processing request:\n $_req", e)
        keepAlive = false
      }

      if (!keepAlive)
        break
      
      _req = parseReq(socket)
    }
    return true
  }

  **
  ** Parse the first request line and request headers.
  ** Return null on failure.
  **
  static HttpReq? parseReq(TcpSocket socket) {
    try {
      // skip leading CRLF (4.1)
      in := socket.in
      line := in.readLine
      if (line == null) return null
      while (line.isEmpty) {
        line = in.readLine
        if (line == null) return null
      }

      // parse request-line (5.1)
      toks   := line.split
      method := toks[0]
      uriStr := toks[1]
      verStr := toks[2]

      // uri; immediately reject any uri which starts with ..
      uri := Uri.decode(uriStr)
      if (uri.path.first == "..") return null

      // version
      ver := null
      if (verStr == "HTTP/1.1") ver = HttpReq.ver11
      else if (verStr == "HTTP/1.0") ver = HttpReq.ver10
      else return null

      return HttpReq {
        it.method = method.upper
        it.uri = uri
        it.version = ver
        it.headers = WebUtil.parseHeaders(in).ro //case-insensitive already
        it.remoteAddr = socket.remoteAddr
        it.remotePort = socket.remotePort
      }
    } catch (Err e) {
      return null
    }
  }
  
  internal Bool writeResponse(HttpRes res, HttpReq req, OutStream out) {
    Bool keepAlive := false
    
    headers := res.headers.dup // we’re going to modify it
    content := res.body
    contentLength := getHeader(headers, "content-length")?.toInt
    
    if (content != null && contentLength == null)
      if (content.typeof.slot("size", false) != null) {
        contentLength = content->size
        headers.add(["Content-Length", contentLength.toStr])
      }
    
    // if client doesn’t say explicitly that he’s going to reuse connection,
    // it’s safer not to keep it alive
    if(req.headers["connection"]?.lower == "keep-alive") {
      headers.add(["Connection", "Keep-Alive"])
      keepAlive = true
    }
    
    out.print("HTTP/1.1 ")
       .print(res.status)
       .print(" ")
       .print(WebRes.statusMsg[res.status])
       .print("\r\n")
    printHeaders(headers, out)
    out.print("\r\n")
    
    if (content == null || contentLength == 0)
      return keepAlive
    
    if (contentLength != null)
      out = WebUtil.makeFixedOutStream(out, contentLength)
    else
      out = WebUtil.makeChunkedOutStream(out)
    
    if (content is InStream)
      (content as InStream).pipe(out)
    else if (content is File)
      (content as File).in.pipe(out, (content as File).size)
    else if (content is Buf)
      out.writeBuf(content)
    else
      throw ArgErr("Unknown res.body type: ${res.body.typeof}, "
                 + "known types are: InStream, File, Buf")
    return keepAlive
  }
  
  internal Str? getHeader(Str[][] headers, Str name) {
    tuple := headers.find { it[0].equalsIgnoreCase(name) }
    return tuple == null ? null : tuple[1]
  }
  
  internal Void printHeaders(Str[][] headers, OutStream out) {
    headers.each {
      k := it[0]
      v := it[1]
      out.print("$k: $v\r\n")
    }
    out.print("Server: $serverVer\r\n")
    out.print("Date: " + DateTime.now.toHttpStr + "\r\n")
  }
}