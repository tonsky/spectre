
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
  static Settings? app() { (appRef.val as Unsafe)?.val as Settings }
  static Void setApp(Settings s) { appRef.val = Unsafe(s) }
  
  static const AtomicRef activePodRef := AtomicRef()
  static Pod? activePod() { (activePodRef.val as Unsafe)?.val as Pod }
  static Void setActivePod(Pod s) { activePodRef.val = Unsafe(s) }
  
  override Int run() {
    return runServices([ WebServer {
      processorPool = ActorPool { maxThreads = 101 }
      it.port = this.port
      httpProcessor := SpectreHttpProcessor(appDir)
      protocols = [AppReloadProtocol(appDir),
                   WsProtocol { RunDevServer.app.wsProcessor(it) },
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
    app := activeApp
    if (app !== RunDevServer.app)
      RunDevServer.setApp(app)
  }
  
  override Bool onConnection(HttpReq req, TcpSocket socket) {
    app := activeApp
    if (app != null && app !== RunDevServer.app)
      RunDevServer.setApp(app)
    return false // pass through to next protocol
  }
  
  File podDir() { watchPodActor.podDir }
  
  virtual Settings? activeApp() {
    try {
      Obj? loadedPodObj := watchPodActor.send(null).get
      loadedPod := loadedPodObj as Pod
      if (loadedPod !== RunDevServer.activePod) {
        startApp(loadedPod)
        RunDevServer.setActivePod(loadedPod)
      }
    } catch(build::FatalBuildErr err) {
      log.err("App compilation error: ${podDir}build.fan", err)
    } catch(Err err) {
      log.err("Error occured", err)
    }
    return RunDevServer.app
  }
  
  virtual Void startApp(Pod appPod) {
    log.info("Starting pod $appPod")
    Type? settingsType := appPod.types.find { it.fits(Settings#) }
    if (settingsType == null)
      throw Err("Cannot find spectre::Settings implementation in ${podDir}")
    
    Settings settings := settingsType.make([podDir])
    RunDevServer.setApp(settings)
  }
}

const class SpectreHttpProcessor {
  private const static Log log := Log.get("spectre")
  private const File podDir
  
  new make(File podDir) { this.podDir = podDir }
  
  HttpRes onRequest(HttpReq httpReq) {
    try {
      Req req := SpectreReq(httpReq, RunDevServer.app)
      Res? response := RunDevServer.app.root.dispatch(req)
      
      if(response != null)
        return httpRes(response)
      else
        throw Err("App returned empty response")
    } catch (build::FatalBuildErr err) {
      log.err("App compilation error: ${podDir}build.fan", err)
      return httpRes(ResServerError("<h1>500 App compilation error</h1>"
                                  + "<pre>App path: ${podDir}build.fan\n\n"
                                  + "${Util.traceToStr(err)}</pre>"))
    } catch (Err err) {
      log.err("Error occured", err)
      return httpRes(ResServerError("<h1>500 Internal server error</h1>"
                                  + "<pre>${Util.traceToStr(err)}</pre>"))
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
