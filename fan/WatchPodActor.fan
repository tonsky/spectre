
using web
using concurrent
using build

const class WatchPodActor : Actor {
  const File podDir
  const Uri buildFileName
  const Regex wathedFiles := Regex <|.*\.fan|>
  const static Log log := WatchPodActor#.pod.log
  
  new make(ActorPool p, File podDir, Uri buildFileName := `build.fan`): super(p) {
    log.info("Watching $podDir for modifications")
    
    this.podDir = podDir.normalize
    this.buildFileName = buildFileName
  }
  
  **
  ** Returns cached instance of Pod's App instance
  ** Invalidates cache and reloads Pod if any *.fan files were changed in podDir
  ** 
  protected override App? receive(Obj? msg) {
    File? modified := Util.findFirstFile(podDir) |f| {
      wathedFiles.matches(f.name) && f.modified > Actor.locals["spectre.last_modified"]
    }

    if (modified != null || Actor.locals["spectre.app"] == null) {
      try{
        if (log.isDebug && modified != null)
          log.debug("Found modified file $modified")
        
        Pod appPod := reloadPod()
        appType := appPod.types.find { it.fits(App#) }
        if (appType == null)
          throw Err.make("Cannot find spectre::App implementation in $podDir")
        
        Actor.locals["spectre.app_dir"] = podDir
        Actor.locals["spectre.app"] = appType.make
        Actor.locals["spectre.last_modified"] = DateTime.now
      } catch(Err err) {
        log.err("", err)
      } finally {
        Actor.locals["spectre.ver"] = 1 + Actor.locals["spectre.ver"]
      }
    }
    
    return Actor.locals["spectre.app"]
  }
  
  Pod reloadPod() {
    // extracting BuildPod type
    buildFile := podDir + buildFileName
    buildPodType := Env.cur.compileScript(buildFile)
    BuildPod buildPod := buildPodType.make()
    
    // customizing temporary build
    buildPod.outDir = Env.cur.tempDir.uri
    buildPod.podName = tmpPodName(buildPod)
    buildPod.log.level = LogLevel.err
    
    // building and loading rebuilded pod
    buildPod.compile()
    File f := buildPod.outDir.toFile + Uri.fromStr(buildPod.podName + ".pod")
    log.info("Rebuildind pod $podDir.name as $f")
    pod := Pod.load(f.in)
    if (log.isDebug)
      log.debug("Pod loaded: $f")
    f.delete
    if (log.isDebug)
      log.debug("[Temporary file removed] $f")
    
    return pod
  }
  
  Str tmpPodName(BuildPod buildPod) {
    return buildPod.podName += "_reloaded_" + Actor.locals.getOrAdd("spectre.ver") { 1 }
  }
}