using concurrent
using inet::IpAddr


enum class ProtocolRes { skip, keep, close }

mixin Protocol {
  abstract ProtocolRes onFirstConnection(HttpReq req, TcpSocket socket)
  abstract ProtocolRes onNextConnections(TcpSocket socket)
}

const class WebServer : Service {
  private static const Log log := WebServer#.pod.log
  
  const Protocol[] protocols

  ** Binding params
  const Str? bindAddr := null
  const Int port := 80

  internal const ActorPool   listenerPool    := ActorPool { maxThreads = 1 }
  internal const ActorPool   processorPool   := ActorPool()
  internal const SelActor    selActor        := SelActor(listenerPool)

  new make(|This| f) { f.call(this) }
  
  override Void onStart() {
    if (listenerPool.isStopped) throw Err("spectre::WebServer is already stopped, use new instance to restart")
    
    listener := TcpListener(|SelActor sel, TcpListener lnr->Void| {
      TcpSocket? socket := lnr.accept
      reader := SocketProcessor(processorPool)
      socket.readReady = |SelActor _sel, TcpSocket _socket->Void| {
        reader->sendProcess(Unsafe(_sel), Unsafe(_socket), Unsafe(protocols))
      }
      sel.sendRegister([socket, lnr])
    })
    
    listener.bind(bindAddr == null ? null : IpAddr(bindAddr), port)
    selActor.sendRegister([listener]) // starting selector thread
    
    log.info("spectre::WebServer is listening on port ${port}")
  }

  override Void onStop() {
    selActor.stop
    try listenerPool.stop;   catch (Err e) log.err("spectre::WebServer error stopping listener pool", e)
    try processorPool.stop;  catch (Err e) log.err("spectre::WebServer error stopping processor pool", e)
  }
}

const class SocketProcessor : DynActor {
  override protected const Log log := Log.get("spectre")
  Protocol? _protocol { get { Actor.locals["spectre.WebServerAcceptor._protocol"] }
                        set { Actor.locals["spectre.WebServerAcceptor._protocol"] = it } }
   
  new make(ActorPool pool) : super(pool) {}
  
  protected Void _process(SelActor sel, TcpSocket socket, Protocol[] protocols) {
    try {
      res := ProtocolRes.skip
      if (_protocol == null) { // first time
        socket.options.receiveTimeout = 10sec
        // First time we are parsing header by ourself
        req := HttpProtocol.parseReq(socket)
        if (req == null) {
          log.debug("HttpReq parsing failed (incorrect http header?): $req")
          socket.close
          return
        }
        
        // Finding appropriate protocol handler
        _protocol = protocols.find |p->Bool| { res = p.onFirstConnection(req, socket); return res != ProtocolRes.skip; }

        // After connection has been processed or no processors found
        if (_protocol == null) throw Err("No protocol found to process this connection:\n $req")
      } else
        res = _protocol.onNextConnections(socket)
      
      if (res == ProtocolRes.keep && !socket.isClosed)
        sel.sendRegister([socket]) // listening for following messages
      else
        socket.close
    } catch(Err e) {
      log.err("Error processing connection $socket", e);
      socket.close
    }
  }
}
