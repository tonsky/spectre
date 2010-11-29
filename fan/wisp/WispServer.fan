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
  
  override Void onService() {
    try {
      Req req := WebletReq()
      
      Res? response := activeApp.dispatch(req)
      if(response != null)
        writeResponse(response)
      else {
        throw Err("App returned empty response")
      }
    } catch(build::FatalBuildErr err) {
      log.err("App compilation error: ${podDir}build.fan", err)

      res.statusCode = 500
      res.headers["Content-Type"] = "text/html"
      res.out.writeChars("<h1>500 App compilation error</h1>"
                       + "<pre>App path: ${podDir}build.fan\n\n"
                       + "${Util.traceToStr(err)}</pre>")
      res.done
    } catch(Err err) {
      log.err("Error occured", err)

      res.statusCode = 500
      res.headers["Content-Type"] = "text/html"
      res.out.writeChars("<h1>500 Internal server error</h1>"
                       + "<pre>${Util.traceToStr(err)}</pre>")
      res.done
    }
  }
  
  virtual Void writeResponse(Res response) {
    response.beforeWrite
    res.headers.addAll(response.headers.asMultimap.map |v,k| { v.join("\r\n$k: ") })
    res.statusCode = response.statusCode
    res.out.charset = response.charset
    response.writeBody(res.out)
    res.done
  }
}
