using build
class Build : build::BuildPod {
  new make() {
    podName = "newappname"
    summary = ""
    srcDirs = [`fan/`]
    depends = ["spectre 1.0", "sys 1.0"]
  }
}
