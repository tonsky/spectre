using concurrent
using util
using web

class RunDevServer : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  @Arg { help = "path to app dir (must contains build.fan and spectre::App implementation)" }
  File? appDir
  
  override Int run() {
    return runServices([ WebServer { it.port = this.port; protocols = [SpectreWSProtocol(), SpectreHttpProtocol(appDir)] } ])
  }
}

class DevServerReq : Req {
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

const class SpectreWSActor : DynActor {
  OutStream out { get { Actor.locals["spectre.ws_actor.out"] }
                  set { Actor.locals["spectre.ws_actor.out"] = it } }
  
  new make(ActorPool pool, OutStream out) : super(pool) {
    this->sendSetOut(Unsafe(out))
    this.sendLater(Duration("500ms"), DynActorCommand(#_sendSmth, ["Hello from webSocket!!!"]))
    this.sendLater(Duration("1500ms"), DynActorCommand(#_sendSmth, ["Hello again"]))
  }
  
  protected Void _echo(Str msg) { _sendSmth("You sent: " + msg) }
  
  protected Void _sendSmth(Str msg) { WebSocketDataFrame_HIXIE_76 { data = msg.toBuf }.write(out) }
  
  protected Void _setOut(OutStream out) { this.out = out }
}


const class SpectreWSProtocol : WebSocketProtocol {
  const ActorPool pool := ActorPool()
  
  override WebSocketHandshakeRes onHandshake(WebSocketHandshakeReq req, OutStream out) {
    return WebSocketHandshakeRes(req) { processor = SpectreWSActor(pool, out) } 
  }
  
  override Void onMessage(Actor processor, Buf data) { processor->sendEcho(data.readAllStr) }
}

const class SpectreHttpProtocol : HttpProtocol {
  private const static Log log := Log.find("spectre")
  
  const WatchPodActor watchPodActor
  
  new make(File podDir) {
    pool := ActorPool { maxThreads = 1 }
    watchPodActor = WatchPodActor.make(pool, podDir)

    // trying to load app
    try {
      activeApp
    } catch(build::FatalBuildErr err) {
      log.err("App compilation error: ${podDir}build.fan", err)
    } catch(Err err) {
      log.err("Error occured", err)
    }
  }
  
  Pod? activePod { get { Actor.locals["spectre.app_pod"] } 
                   set { Actor.locals["spectre.app_pod"] = it } }
  
  File podDir() { watchPodActor.podDir }
  
  virtual Turtle activeApp() {
    Obj? loadedPodObj := watchPodActor.send(null).get
    if (loadedPodObj is Err)
      throw loadedPodObj

    loadedPod := loadedPodObj as Pod
    
    if (loadedPod !== activePod) {
      restartApp(loadedPod)
      activePod = loadedPod
    }
    return Settings.instance.root
  }
  
  virtual Void restartApp(Pod appPod) {
    log.info("Restarting pod $appPod")
    Type? settingsType := appPod.types.find { it.fits(Settings#) }
    if (settingsType == null)
      throw Err.make("Cannot find spectre::Settings implementation in ${podDir}")
    
    Settings settings := settingsType.make([podDir])
    Settings.setInstance(settings)
  }
  
  override Bool onRequest(HttpReq httpReq, OutStream out) {
    try {
      Req req := DevServerReq(httpReq)
      Res? response := activeApp.dispatch(req)
      
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
