
using web
using concurrent
using build

class PodReloader {
  const File podDir
  const Uri buildFileName
  const Regex wathedFiles := Regex <|.*\.fan|>
  private const static Log log := Log.get("spectre")
  
  new make(File podDir, Uri buildFileName := `build.fan`) {
    log.info("Watching $podDir for modifications")    
    this.podDir = podDir.normalize
    this.buildFileName = buildFileName
  }

  DateTime lastModified := DateTime.makeTicks(0)
  Int ver := 1
  Pod? pod
  
  ** Returns cached instance of Pod's App instance
  ** Invalidates cache and reloads Pod if any of *.fan files were changed in podDir
  Pod getLatest() {
    File? modified := Util.findFirstFile(podDir) |f| {
      wathedFiles.matches(f.name) && f.modified > lastModified 
    }
    
    if (modified != null || pod == null) {
      try {
        if (log.isDebug && modified != null)
          log.debug("Found modified file $modified")
        
        pod = reloadPod()
        lastModified = DateTime.now
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