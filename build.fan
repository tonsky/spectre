using build
class Build : build::BuildPod
{
  new make()
  {
    version = Version.fromStr("0.8")
    podName = "spectre"
    summary = ""
    srcDirs = [`test/`, `test/forms/`, `fan/`, `fan/wisp/`, `fan/util/`, `fan/forms/`, `fan/contrib/`, `fan/contrib/views/`, `fan/contrib/template/`, `fan/contrib/sessions/`]
    depends = ["sys 1.0",
               "build 1.0",
               "compiler 1.0",
               "web 1.0",
               "util 1.0",
               "webmod 1.0",
               "wisp 1.0",
               "concurrent 1.0",
      
               "mustache 1.0",
               "printf 1.0"]
  }
}
