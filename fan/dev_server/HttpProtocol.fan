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

abstract const class HttpProtocol : Protocol {
  private static const Log log := HttpProtocol#.pod.log

  ** To be implemented in descendants
  ** Return 'false' if connection should not be reused
  abstract Bool onRequest(HttpReq req, OutStream out)
  
  override Bool onConnection(HttpReq req) {
    socket := req.socket
    in := socket.in
    out := socket.out
    
    HttpReq? _req := req
    while(_req != null) {
      keepAlive := false
      try {
        _req.in = WebUtil.makeContentInStream(_req.headers, in)
        keepAlive = onRequest(_req, out)

        try {
          out.flush
          
          // if the listener didn’t finishing reading the content
          // stream then don’t attempt to reuse this connection,
          // safest thing is to just close the socket
          if (!req.isAllRead)
            keepAlive = false
        } catch (IOErr e) {
          keepAlive = false
        }
      } catch(Err e) {
        log.err("Error processing request:\n $_req", e)
        keepAlive = false
      }
      
      // if client doesn’t say explicitly that he’s going to reuse connection, it’s safer to close it
      keepAlive = keepAlive && _req.headers.get("Connection", "").equalsIgnoreCase("keep-alive")
      
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
      req.headers = WebUtil.parseHeaders(in).ro

      req.in = in
      
      // success
      return req
    } catch (Err e) {
      return null
    }
  }
}