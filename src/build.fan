using build
class Build : build::BuildPod {
  new make() {
    version = Version.fromStr("0.8.2")
    podName = "spectre"
    summary = ""
    srcDirs = [`fan/`,
               `fan/asyncio/`,
               `fan/commands/`,
               `fan/contrib/messages/`,
               `fan/contrib/sessions/`,
               `fan/contrib/template/`,
               `fan/contrib/views/`,
               `fan/dev_server/`,
               `fan/forms/`,
               `fan/util/`,
               `test/`,
               `test/asyncio/`,
               `test/dev_server/`,
               `test/forms/`,
               `test/util/`,
               ]
    javaDirs = [`java/`]
    resDirs = [`res/startapp/`]
    
    depends = ["sys 1.0",
               "build 1.0",
               "compiler 1.0",
               "inet 1.0",
               "web 1.0",
               "util 1.0",
               "webmod 1.0",
               "concurrent 1.0",
               // "wisp 1.0",

               "mustache 1.0",
               "printf 1.0"]               
  }
  
  
  File spectreRepoDir := scriptDir + `../`
  File outDistrDir := scriptDir + `../`
  
  @Target { help = "Run clean, compile, and test" }
  virtual Void dist() {
    log.info("dist [spectre]")
    log.indent
    
    log.info("Create temp destination [spectre]")
    log.indent

    tmpDest := outDistrDir + `spectre-$version/`
    libFan := tmpDest+`lib/fan/`

    CreateDir(this, tmpDest).run
    CreateDir(this, tmpDest+`lib/`).run
    CreateDir(this, libFan).run
    
    log.info("Copy dependencies [$tmpDest]")
    Env.cur.findPodFile("printf").copyInto(libFan)
    Env.cur.findPodFile("mustache").copyInto(libFan)
    Env.cur.findPodFile("spectre").copyInto(libFan)

    log.info("Copy files [$tmpDest]")
    spectreRepoDir.copyTo(tmpDest, ["exclude": |File f->Bool| {
      f.name.startsWith(".") || f.ext == "orig" || f == tmpDest
    }, "overwrite": true])
    
    log.unindent

    File target := outDistrDir + `spectre-${version}.zip`
    CreateZip(this) { outFile = target; inDirs = [tmpDest] }.run
    
    Delete(this, tmpDest).run
  }
}
