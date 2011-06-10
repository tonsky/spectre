using build
class Build : build::BuildPod {
  new make() {
    podName = "newappname"
    summary = ""
    srcDirs = [`fan/`]
    depends = ["spectre 0.8+", "sys 1.0"]
  }
}
