using inet
using web

class HttpReq {
  static const Version nullVersion := Version("0")
  static const Version ver10 := Version("1.0")
  static const Version ver11 := Version("1.1")
  static const Str:Str nullHeaders := Str:Str[:]
  
  internal TcpSocket socket
  SocketOptions socketOptions() { socket.options }

  InStream? in { get { &in ?: throw Err("Attempt to access WebReq.in with no content") } }

  Str method := ""
  Version version := nullVersion
  IpAddr remoteAddr() { return socket.remoteAddr }
  Int remotePort() { return socket.remotePort }
  Str:Str headers := nullHeaders
  Uri uri := ``

  new make(TcpSocket socket) { this.socket = socket }
  new makeTest(InStream in) { this.socket = TcpSocket(); this.in = in }
  virtual Bool isAllRead() { &in == null || &in.peek == null }
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

abstract const class HttpProtocol : Protocol {
  private static const Log log := HttpProtocol#.pod.log
  static const Str serverVer   := "SpectreDevServer/" + HttpProtocol#.pod.version
  
  **
  ** To be implemented in descendants
  ** 
  abstract HttpRes onRequest(HttpReq req)

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
  
  internal Void printHeaders(Str[][] headers, OutStream out) {
    headers.each {
      k := it[0]
      v := it[1]
      out.print("$k: $v\r\n")
    }
    out.print("Server: $serverVer\r\n")
    out.print("Date: " + DateTime.now.toHttpStr + "\r\n")
  }
  
  internal Str? getHeader(Str[][] headers, Str name) {
    tuple := headers.find { it[0].equalsIgnoreCase(name) }
    return tuple == null ? null : tuple[1]
  }
  
  override Bool onConnection(HttpReq req) {
    socket := req.socket
    in := socket.in
    out := socket.out
    
    HttpReq? _req := req
    while(_req != null) {
      keepAlive := false
      try {
        _req.in = WebUtil.makeContentInStream(_req.headers, in)
        res := onRequest(_req)
        keepAlive = writeResponse(res, _req, out)

        try {
          out.flush
          
          // if the listener didn’t finishing reading the content
          // stream then don’t attempt to reuse this connection,
          // safest thing is to just close the socket
          if (!req.isAllRead) {
            keepAlive = false
          }
        } catch (IOErr e) {
          keepAlive = false
        }
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
      req := HttpReq(socket)
      
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
      uri    := toks[1]
      ver    := toks[2]

      // method
      req.method = method.upper

      // uri; immediately reject any uri which starts with ..
      req.uri = Uri.decode(uri)
      if (req.uri.path.first == "..") return null

      // version
      if (ver == "HTTP/1.1") req.version = HttpReq.ver11
      else if (ver == "HTTP/1.0") req.version = HttpReq.ver10
      else return null

      // parse headers
      req.headers = WebUtil.parseHeaders(in).ro //case-insensitive already

      req.in = in
      
      // success
      return req
    } catch (Err e) {
      return null
    }
  }
}