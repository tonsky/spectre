using build
class Build : build::BuildPod {
  new make() {
    podName = "getting_started"
    summary = ""
    srcDirs = [`fan/`]
    depends = ["sys 1.0", "spectre 0.8"]
  }
}