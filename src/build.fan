using build
class Build : build::BuildPod {
  new make() {
    version = Version.fromStr("1.0")
    podName = "spectre"
    summary = ""
    srcDirs = [`fan/`,
               `fan/asyncio/`,
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
}
