
using concurrent
using inet
using web

//TODO const
class HttpReq {
  
  static const Version nullVersion := Version("0")
  static const Str:Str nullHeaders := Str:Str[:]

  internal TcpSocket socket
  InStream? in { get { &in ?: throw Err("Attempt to access WebReq.in with no content") } }

  Str method := ""
  Version version := nullVersion
  IpAddr remoteAddr() { return socket.remoteAddr }
  Int remotePort() { return socket.remotePort }
  Str:Str headers := nullHeaders
  Uri uri := ``

  SocketOptions socketOptions() { socket.options }

  new make(TcpSocket socket) {
    this.socket = socket
  }

  new makeTest(InStream in) {
    this.socket = TcpSocket()
    this.in = in
  }
 
  virtual Bool isAllRead() { &in == null || &in.peek == null }
  
  override Str toStr() {
    "$method $uri HTTP/$version\n " + headers.join("\n ")      
  }
}


const mixin ConnectionListener {
  abstract Bool onConnection(HttpReq req, OutStream out)
}

const mixin HttpConnectionListener : ConnectionListener {
  private static const Log log := Log.get("spectre")
  
  override Bool onConnection(HttpReq req, OutStream out) {
    HttpReq? _req := req
    while(_req != null) {
      _req.in = WebUtil.makeContentInStream(_req.headers, req.socket.in)
      
      success := false
      
      try {
        // assume success which allows us to re-use this connection
        success = onMessage(_req, out)
  
        // if the listener didn’t finishing reading the content
        // stream then don’t attempt to reuse this connection,
        // safest thing is to just close the socket
        try {
          out.flush
          if (!_req.isAllRead())
            success = false
        } catch (IOErr e) {
          success = false
        }
      } catch(Err e) {
        log.warn("Error processing message:\n $_req", e)
        //TODO report error to browser
      }
      
      if (success && (_req.version === DevServerProcessActor.ver11 && !_req.headers.get("Connection", "").equalsIgnoreCase("close"))
        || (_req.version === DevServerProcessActor.ver10 && _req.headers.get("Connection", "").equalsIgnoreCase("keep-alive"))) {
          // keeping connection alive
        _req = readReq(req.socket)
      } else {
        // terminating socket
        break
      }
    }
    
    try { req.socket.close } catch {}
    
    return true
  }
  
  virtual HttpReq? readReq(TcpSocket socket) {
    return DevServerProcessActor.parseReq(socket)
  }
  
  // return false if connection should be closed, true otherwise
  abstract Bool onMessage(HttpReq req, OutStream out)
}

//abstract const class WebSocketProcessorActor : DynActor {
//  new make(ActorPool pool) :super(pool) {}
//  abstract Void _onMessage(WebSockedDataFrame frame)
//}
//
//abstract const class WebSocketConnectionListener : ConnectionListener {
//  override Bool onConnection(HttpReq req, OutStream out) {
//    if (!req.headers["Connection"].equalsIgnoreCase("Upgrade") ||
//      !req.headers["Upgrade"].equalsIgnoreCase("Upgrade"))
//      return false
//  
//    processor := processor(req, out)
//    
//    while(req.in.peek != null) {
//      processor->sendOnMessage(readFrame(req.in))
//    }
//    return true
//  }
//  
//  virtual WebSockedDataFrame readFrame(InStream in) {
//    return WebSockedDataFrame {/*TODO*/} 
//  }  
//  
//  abstract WebSocketProcessorActor processor(HttpReq req, OutStream out)
//}

const class DevServer : Service {
  
  const ConnectionListener[] listeners
  
  static const Log log := Log.get("spectre")
  const TcpListener listener := TcpListener()
  const ActorPool listenerPool    := ActorPool()
  const ActorPool processorPool   := ActorPool()

  new make(|This| f) { f.call(this) }
  

  **
  ** Well known TCP port for HTTP traffic.
  **
  const Int port := 80

  override Void onStart() {
    if (listenerPool.isStopped) throw Err("DevServer is already stopped, use to new instance to restart")
    DevServerListenActor(listenerPool)->sendListen(listener, port, processorPool, listeners)
  }

  override Void onStop() {
    try listener.close;      catch (Err e) log.err("WispService stop listener socket", e)
    try listenerPool.stop;   catch (Err e) log.err("WispService stop listener pool", e)
    try processorPool.stop;  catch (Err e) log.err("WispService stop processor pool", e)
  }
}

const class DevServerListenActor : DynActor {
  internal static const Log log := Log.get("spectre")
  
  new make(ActorPool pool) : super(pool) {}
  
  protected Void _listen(TcpListener tcpListener, Int port, ActorPool processorPool, ConnectionListener[] listeners) {
    // loop until we successfully bind to port
    while (true) {
      try {
        tcpListener.bind(null, port)
        break
      } catch (Err e) {
        log.err("DevServer cannot bind to port ${port}, trying again in 10 seconds", e)
        Actor.sleep(10sec)
      }
    }
    log.info("DevServer started on port ${port}")

    // loop until stopped accepting incoming TCP connections
    while (!pool.isStopped) {
      try {
        socket := tcpListener.accept
        DevServerProcessActor(processorPool)->sendOnConnect(Unsafe(socket), listeners)
      } catch (Err e) {
        if (!pool.isStopped)
          log.err("DevServer accept on ${port}", e)
      }
    }

    // socket should be closed by onStop, but do it again to be really sure
    try { tcpListener.close } catch {}
    log.info("DevServer stopped on port ${port}")
  }
}

const class DevServerProcessActor : DynActor {
  internal static const Log log := Log.get("spectre")
  
  static const Version ver10 := Version("1.0")
  static const Version ver11 := Version("1.1")
  
  new make(ActorPool pool) : super(pool) {}
  
  protected Void _onConnect(TcpSocket socket, ConnectionListener[] listeners) {
    try {
      socket.options.receiveTimeout = 10sec
      
      req := parseReq(socket)
      if (req == null) {
        log.debug("Incorrect http header")
        return
      }
      
      found := listeners.find { onConnection(req, socket.out) }
      if (found == null)
        throw Err("No listeners to process connection:\n $req")
      
    } catch(Err e) {
      log.err("Error processing connection", e)
    } finally {
      try socket.close; catch {}
    }
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
      if (ver == "HTTP/1.1") req.version = ver11
      else if (ver == "HTTP/1.0") req.version = ver10
      else return null

      // parse headers
      req.headers = WebUtil.parseHeaders(in).ro

      // success
      return req
    } catch (Err e) {
      return null
    }
  }
}