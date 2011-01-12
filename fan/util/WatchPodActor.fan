
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

  DateTime lastModified { get { Actor.locals["spectre.watch_pod.last_modified"] ?: DateTime.makeTicks(0) }
                          set { Actor.locals["spectre.watch_pod.last_modified"] = it } }
  
  Int ver { get{ Actor.locals.getOrAdd("spectre.watch_pod.ver") { 1 } }
            set{ Actor.locals["spectre.watch_pod.ver"] = it } }
  
  Pod? pod { get{ Actor.locals["spectre.watch_pod.pod"] }
             set{ Actor.locals["spectre.watch_pod.pod"] = it } }
  **
  ** Returns cached instance of Pod's App instance
  ** Invalidates cache and reloads Pod if any *.fan files were changed in podDir
  ** 
  protected override Obj? receive(Obj? msg) {
    File? modified := Util.findFirstFile(podDir) |f| {
      wathedFiles.matches(f.name) && f.modified > lastModified 
    }
    
    if (modified != null || pod == null) {
      try {
        if (log.isDebug && modified != null)
          log.debug("Found modified file $modified")
        
        pod = reloadPod()
        lastModified = DateTime.now
      } catch(Err err) {
//        log.err("Error", err)
        return err
      } finally {
        ver = ver + 1
      }
    }
    return pod
  }
  
  Pod reloadPod() {
    // extracting BuildPod type
    buildFile := podDir + buildFileName
    buildPodType := Env.cur.compileScript(buildFile)
    BuildPod buildPod := buildPodType.make()
    
    // customizing temporary build
    buildPod.outDir = Env.cur.tempDir.uri
    buildPod.podName = tmpPodName(buildPod)
    buf := StrBuf().add("\n")
    buildPod.log = BuildLog(buf.out)
    buildPod.log.indent
    buildPod.log.level = LogLevel.info
    buildPod.docApi = false // docs cannot be loaded anyway
    
    try {
      // building and loading rebuilded pod
      buildPod.compile()
      File f := buildPod.outDir.toFile + Uri.fromStr(buildPod.podName + ".pod")
      log.info("Rebuildind pod $podDir.name as $f")
      loadedPod := Pod.load(f.in)
      if (log.isDebug)
        log.debug("Pod loaded: $f")
      try {
        f.delete
      }catch(IOErr err) {
        f.deleteOnExit
      }
      if (log.isDebug)
        log.debug("[Temporary file removed] $f")
      
      return loadedPod
    } catch (FatalBuildErr err) {
      throw FatalBuildErr(buf.toStr)
    }    
  }
  
  Str tmpPodName(BuildPod buildPod) {
    return buildPod.podName += "_reloaded_" + ver
  }
}