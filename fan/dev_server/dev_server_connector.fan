
using concurrent
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
      it.port = this.port
      protocols = [AppReloadProtocol(appDir),
                   SpectreWsProtocol(),
                   SpectreHttpProtocol(appDir)] 
    } ])
  }
}

const class AppReloadProtocol : Protocol {
  private const static Log log := Log.find("spectre")
  const WatchPodActor watchPodActor

  new make(File podDir) {
    pool := ActorPool { maxThreads = 1 }
    watchPodActor = WatchPodActor.make(pool, podDir)

    // trying to load app
    activeApp
  }

  override Bool onConnection(HttpReq req) {
    app := activeApp
    if (app !== RunDevServer.app)
      RunDevServer.setApp(app)
    return false // pass through to next protocol
  }
  
  File podDir() { watchPodActor.podDir }
  
  virtual Settings activeApp() {
    try {
      Obj? loadedPodObj := watchPodActor.send(null).get
      if (loadedPodObj is Err)
        throw loadedPodObj
  
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
      throw Err.make("Cannot find spectre::Settings implementation in ${podDir}")
    
    Settings settings := settingsType.make([podDir])
    RunDevServer.setApp(settings)
  }
}

const class SpectreWsProtocol : WsProtocol {
  override WsActor createWsActor(WsHandshakeReq req) {
    RunDevServer.app.createWsActor(req)
  }
}

const class SpectreHttpProtocol : HttpProtocol {
  private const static Log log := Log.find("spectre")
  private const File podDir
  
  new make(File podDir) { this.podDir = podDir }
  
  override Bool onRequest(HttpReq httpReq, OutStream out) {
    try {
      Req req := SpectreReq(httpReq)
      Res? response := RunDevServer.app.root.dispatch(req)
      
      if(response != null)
        writeResponse(response, out)
      else
        throw Err("App returned empty response")
    } catch(build::FatalBuildErr err) {
      log.err("App compilation error: ${podDir}build.fan", err)
      writeResponse(ResServerError("<h1>500 App compilation error</h1>"
                                 + "<pre>App path: ${podDir}build.fan\n\n"
                                 + "${Util.traceToStr(err)}</pre>"), out)
    } catch(Err err) {
      log.err("Error occured", err)
      writeResponse(ResServerError("<h1>500 Internal server error</h1>"
                                 + "<pre>${Util.traceToStr(err)}</pre>"), out)
    }
    return true
  }
  
  virtual Void writeResponse(Res response, OutStream out) {
    needOut := response.beforeWrite
    
    out.print("HTTP/1.1 ")
       .print(response.statusCode)
       .print(" ")
       .print(WebRes.statusMsg[response.statusCode])
       .print("\r\n")
    
    response.headers.asMultimap.each |v,k| { v.each { out.print("$k: $it\r\n") } }
    out.print("Connection: Keep-Alive\r\n")
    out.print("\r\n").flush
    
    if (needOut) {
      cout := WebUtil.makeContentOutStream(response.headers.asMap, out)
      if (cout == null)
        cout = out
      
      cout.charset = response.charset
      response.writeBody(cout)
    }
  }
}

class SpectreReq : Req {
  HttpReq req
  new make(HttpReq req) { this.req = req }
  
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
