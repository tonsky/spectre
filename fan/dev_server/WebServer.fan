
using concurrent
using inet

mixin Protocol {
  abstract Bool onConnection(HttpReq req, TcpSocket socket)
}

const class WebServer : Service {
  private static const Log log := WebServer#.pod.log
  
  const Protocol[] protocols

  ** Binding params
  const Str? bindAddr := null
  const Int port := 80

  internal const Unsafe      tcpListener     := Unsafe(TcpListener())
  internal const ActorPool   listenerPool    := ActorPool { maxThreads = 1 }
  internal const ActorPool   processorPool   := ActorPool()

  new make(|This| f) { f.call(this) }
  
  override Void onStart() {
    if (listenerPool.isStopped) throw Err("spectre::WebServer is already stopped, use new instance to restart")
    WebServerListener(this, listenerPool)->sendListen(tcpListener)
  }

  override Void onStop() {
    try listenerPool.stop;   catch (Err e) log.err("spectre::WebServer error stopping listener pool", e)
    try (tcpListener.val as TcpListener).close; catch (Err e) log.err("spectre::WebServer error closing listener socket", e)    
    try processorPool.stop;  catch (Err e) log.err("spectre::WebServer error stopping processor pool", e)
  }
}

const class WebServerListener : DynActor {
  private static const Log log := WebServerListener#.pod.log
  const WebServer server
  
  new make(WebServer server, ActorPool pool) : super(pool) { this.server = server }
  
  protected Void _listen(TcpListener tcpListener) {
    // loop until we successfully bind to port
    while (true) {
      try {
        tcpListener.bind(server.bindAddr == null ? null : IpAddr(server.bindAddr), server.port)
        break
      } catch (Err e) {
        log.err("spectre::WebServer cannot bind to port ${server.port}, trying again in 10 seconds", e)
        Actor.sleep(10sec)
      }
    }
    log.info("spectre::WebServer started on port ${server.port}")

    // loop until stopped accepting incoming TCP connections
    while (!pool.isStopped) {
      try {
        socket := tcpListener.accept
        WebServerAcceptor(server.processorPool)->sendAccept(Unsafe(socket), server.protocols)
      } catch (Err e) {
        if (!pool.isStopped)
          log.err("spectre::WebServer error accepting on ${server.port}", e)
      }
    }

    // socket should be closed by onStop, but do it again to be really sure
    try { tcpListener.close } catch {}
    log.info("spectre::WebServer stopped on port ${server.port}")
  }
}

const class WebServerAcceptor : DynActor {
  private static const Log log := WebServerAcceptor#.pod.log
   
  new make(ActorPool pool) : super(pool) {}
  
  protected Void _accept(TcpSocket socket, Protocol[] protocols) {
    try {
      socket.options.receiveTimeout = 10sec      
      req := HttpProtocol.parseReq(socket)
      if (req == null) {
        log.debug("HttpReq parsing failed (incorrect http header?): $req")
        return
      }
      
      // Finding appropriate protocol handler
      found := protocols.find { onConnection(req, socket) }
      
      // After connection has been processed or no processors found
      if (found == null)
        throw Err("No listeners to process connection:\n $req")
    } catch(Err e) {
      log.err("Error processing connection", e);
    } finally {
      try socket.close; catch {}
    }
  }
}