using build
class Build : build::BuildPod
{
  new make()
  {
    version = Version.fromStr("1.0")
    podName = "spectre"
    summary = ""
    srcDirs = [`test/`, `test/forms/`, `test/dev_server/`, `fan/`, `fan/util/`, `fan/forms/`, `fan/dev_server/`, `fan/contrib/`, `fan/contrib/views/`, `fan/contrib/template/`, `fan/contrib/sessions/`]
    depends = ["sys 1.0",
               "build 1.0",
               "compiler 1.0",
               "inet 1.0",
               "web 1.0",
               "util 1.0",
               "webmod 1.0",
               "concurrent 1.0",

               "mustache 1.0",
               "printf 1.0"]               
  }
}
