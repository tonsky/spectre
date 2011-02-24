
using concurrent
using inet
using util
using web

class RunServer : RunDevServer {
  override Str mode := "production"
}

class RunDevServer : AbstractMain {
  @Opt { help = "http port" }
  Int port := 8080

  @Arg { help = "path to app dir (must contains build.fan and spectre::App implementation)" }
  File? appDir
  
  virtual Str mode := "development"
  
  static const Duration reloadTimeout := 2000ms
  
  override Int run() {
    return runServices([ WebServer {
      processorPool = ActorPool { maxThreads = 101 }
      it.port = this.port

      appHolder := AppHolder(appDir, mode)
      httpProcessor := SpectreHttpProcessor()
      appHolder->sendGetLatest->get
      
      onWs := |WsHandshakeReq req->WsProcessor?| {
        app := appHolder->sendGetLatest->get->val
        if (app is Err)
          throw (app as Err) ?: Err("I can’t believe it")
        return (app as Settings).wsProcessor(req)
      }
  
      onHttp := |HttpReq req->HttpRes| {
        try {
          app := appHolder->sendGetLatest->get(reloadTimeout)->val
          return httpProcessor.onRequest(req, app)
        } catch(TimeoutErr e) {
          return httpProcessor.onRequest(req, null)
        }
      }
      
      protocols = [WsProtocol(onWs),
                   HttpProtocol(onHttp)]
      
      this.log.info("Server started in " + (mode.equalsIgnoreCase("development") ? "DEVELOPMENT MODE" : "PRODUCTION MODE"))
    } ])
  }
}

const class AppHolder : DynActor {
  private const static Log log := Log.get("spectre")
  
  private const File appDir
  private const Str mode
  
  private static const Str pr := "spectre.app_holder"
  private Obj? app { get { Actor.locals["${pr}.app"] }
                     set { Actor.locals["${pr}.app"] = it } }
  private Pod? appPod { get { Actor.locals["${pr}.app_pod"] }
                       set { Actor.locals["${pr}.app_pod"] = it } }
  private PodReloader podReloader { get { Actor.locals.getOrAdd("${pr}.pod_reloader") { PodReloader(appDir) } }
                                    set { Actor.locals["${pr}.pod_reloader"] = it } }
  
  new make(File appDir, Str mode) : super(ActorPool { maxThreads = 1 }) { 
    this.appDir = appDir
    this.mode = mode.lower
  }
  
  protected virtual Void tryUnload() {
    if (app is Settings) {
      log.info("Unloading ‘$appPod’")
      (app as Settings).onUnload()
      app = null
    }
  }
  
  protected Obj _getLatest() {
    if (app is Settings && mode == "production") // skip reloading then
      return Unsafe(app)
    
    try {
      t0 := DateTime.now
      reloadedPod := podReloader.getLatest
      if (reloadedPod === appPod && app is Settings) {
        if (log.isDebug) log.debug("App is up to date: ‘$appPod’")
        return Unsafe(app)
      }

      tryUnload
      appPod = reloadedPod
      log.info("Loading new version of ‘$appPod’")
      Type? appType := appPod.types.find { it.fits(Settings#) }
      if (appType == null)
        throw Err("Cannot find spectre::Settings implementation in ${appDir}")

      [Str:Obj?][] args := [["appDir": appDir]]
      if (mode == "production")
        args[0]["debug"] = false
      app = appType.make(args)
      log.info("App reloaded in " + (DateTime.now-t0) + ": ‘$appPod’")
      return Unsafe(app)
    } catch (Err e) {
      log.err("Err", e)
      try tryUnload; catch(Err e2) log.err("Err unloading old app", e2)
      app = e
      return Unsafe(e)
    }
  }
}

const class SpectreHttpProcessor {
  private const static Log log := Log.get("spectre")

  HttpRes onRequest(HttpReq httpReq, Obj? app) {
    if (app == null) {
      err := Err("App is reloading now, please try again later")
      response := ResServerError(Handler500.formatText(err, "503 Service Unavailable"), ["statusCode": 503])
      response.headers.add("Retry-After", "1") //1sec
      return httpRes(response)
    } else if (app is build::FatalBuildErr) {
      err := app as build::FatalBuildErr
      return httpRes(ResServerError(Handler500.formatText(err, "500 App Compilation Error")))
    } else if (app is Err) {
      err := app as Err
      return httpRes(ResServerError(Handler500.formatText(err)))
    }
    
    try {
      Req req := SpectreReq(httpReq, app)
      Res? response := (app as Settings).root.dispatch(req)
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
