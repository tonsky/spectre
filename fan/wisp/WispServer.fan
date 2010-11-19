using concurrent
using util
using web
using wisp

class WispServer : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  @Arg { help = "path to app dir (must contains build.fan and spectre::App implementation)" }
  File? appDir
  
  override Int run() {
    return runServices([ WispService { it.port = this.port; root = WispApp(appDir) } ])
  }
}

const class WispApp : WebMod {
  const static Log log := WatchPodActor#.pod.log
  
  const WatchPodActor watchPodActor
  
  new make(File podDir) {
    pool := ActorPool { maxThreads = 1 }
    watchPodActor = WatchPodActor.make(pool, podDir)
  }
  
  Pod? activePod { get { Actor.locals["spectre.app_pod"] } 
                   set { Actor.locals["spectre.app_pod"] = it } }
  
  Turtle activeApp() {
    Pod? loadedPod := watchPodActor.send(null).get
    if (loadedPod !== activePod) {
      restartApp(loadedPod)
      activePod = loadedPod
    }
    return Settings.instance.root
  }
  
  Void restartApp(Pod appPod) {
    log.info("Restarting pod $appPod")
    Type? settingsType := appPod.types.find { it.fits(Settings#) }
    if (settingsType == null)
      throw Err.make("Cannot find spectre::Settings implementation in ${watchPodActor.podDir}")
    
    Settings settings := settingsType.make([watchPodActor.podDir])
    Settings.setInstance(settings)
  }
  
  override Void onService() {
    try {
      Req req := WebletReq()
      
      Res? response := activeApp.dispatch(req)
      if(response != null)
        writeResponse(response)
      else {
        throw Err("App returned empty response")
      }
    } catch(Err err) {
      log.err("Error occured", err)

      res.statusCode = 500
      res.headers["Content-Type"] = "text/html"
      res.out.writeChars("<h1>500 Internal server error</h1>"
                       + "<pre>${Util.traceToStr(err)}</pre>")
      res.done
    }
  }
  
  Void writeResponse(Res response) {
    response.beforeWrite
    res.headers.addAll(response.headers)
    res.statusCode = response.statusCode
    res.out.charset = response.charset
    response.writeBody(res.out)
    res.done
  }
}
