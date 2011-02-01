
using concurrent
using inet
using util
using web

class RunDevServer : AbstractMain {
  @Opt { help = "http port" }
  Int port := 8080

  @Arg { help = "path to app dir (must contains build.fan and spectre::App implementation)" }
  File? appDir
  
  static const AtomicRef appRef := AtomicRef()
  static Obj? app() { (appRef.val as Unsafe)?.val }
  
  static const AtomicRef activePodRef := AtomicRef()
  static Pod? activePod() { activePodRef.val as Pod }
  
  override Int run() {
    return runServices([ WebServer {
      processorPool = ActorPool { maxThreads = 101 }
      it.port = this.port
      httpProcessor := SpectreHttpProcessor(appDir)
      protocols = [AppReloadProtocol(appDir),
                   WsProtocol { (app as Settings)?.wsProcessor(it) },
                   HttpProtocol { httpProcessor.onRequest(it) }] 
    } ])
  }
}

const class AppReloadProtocol : Protocol {
  private const static Log log := Log.get("spectre")
  const WatchPodActor watchPodActor

  new make(File podDir) {
    pool := ActorPool { maxThreads = 1 }
    watchPodActor = WatchPodActor.make(pool, podDir)
    
    // trying to load app
    reloadApp
  }
  
  override Bool onConnection(HttpReq req, TcpSocket socket) {
    reloadApp
    return false // pass through to next protocol
  }
  
  File podDir() { watchPodActor.podDir }
  
  virtual Void reloadApp() {
    Pod? loadedPod
    try {
      loadedPod = watchPodActor.send(null).get
      if (loadedPod === RunDevServer.activePod)
        return
    
      RunDevServer.activePodRef.val = loadedPod
      log.info("Starting pod $loadedPod")
      Type? appType := loadedPod.types.find { it.fits(Settings#) }
      if (appType == null) {
        RunDevServer.appRef.val = Unsafe(Err("Cannot find spectre::Settings implementation in ${podDir}"))
        return
      }
      
      Settings app := appType.make([["appDir": podDir]])
      RunDevServer.appRef.val = Unsafe(app)
    } catch (Err e) {
      RunDevServer.appRef.val = Unsafe(e)
    }
  }
}

const class SpectreHttpProcessor {
  private const static Log log := Log.get("spectre")
  private const File podDir
  
  new make(File podDir) { this.podDir = podDir }
  
  HttpRes onRequest(HttpReq httpReq) {
    if (RunDevServer.app is build::FatalBuildErr) {
      err := RunDevServer.app as build::FatalBuildErr
      return httpRes(ResServerError(Handler500.formatText(err, "500 App Compilation Error")))
    } else if (RunDevServer.app is Err) {
      err := RunDevServer.app as Err
      return httpRes(ResServerError(Handler500.formatText(err)))
    }
    
    try {
      Req req := SpectreReq(httpReq, RunDevServer.app)
      Res? response := (RunDevServer.app as Settings).root.dispatch(req)
      if(response != null)
        return httpRes(response)
      else
        throw Err("App returned empty response")
    } catch (Err err) {
      return httpRes(ResServerError(Handler500.formatText(err)))
    }
  }
  
  HttpRes httpRes(Res res) { 
    HttpRes(res.statusCode,
      res.headers.asList, 
      res.content is Str ? (res.content as Str).toBuf(res.charset) : res.content)
  }
}

class SpectreReq : Req {
  HttpReq req
  override Settings app
  new make(HttpReq req, Settings app) { this.req = req; this.app = app }
  
  once override QueryMap get() { return QueryMap.decodeQuery(req.uri.queryStr).ro }
  once override QueryMap post() { QueryMap.decodeQuery(form).ro }
  once override QueryMap request() { QueryMap.decodeQuery(req.uri.queryStr).setAllMap(post).ro }

  once override Uri pathInfo() { req.uri }
  once override Str:Str headers() { req.headers.ro }
  once override Str method() { req.method }
  
  override InStream in() { req.in }
  
  virtual protected once Str? form() {
    ct := headers.get("Content-Type", "").lower
    if (ct.startsWith("application/x-www-form-urlencoded")) {
      len := headers["Content-Length"]
      if (len == null) throw IOErr("Missing Content-Length header")
      return req.in.readLine(len.toInt)
    }
    return null
  }
}
