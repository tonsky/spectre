using build
class Build : build::BuildPod
{
  new make()
  {
    podName = "spectre"
    summary = ""
    srcDirs = [`test/`, `fan/`]
    depends = ["sys 1.0",
               "build 1.0",
               "compiler 1.0",
               "web 1.0",
               "util 1.0",
               "webmod 1.0",
               "wisp 1.0",
               "concurrent 1.0",
               "mustache 1.0"]
  }
}
