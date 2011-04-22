using build
class Build : build::BuildPod
{
  new make()
  {
    podName = "tour_de_force"
    summary = ""
    srcDirs = [`fan/`]
    depends = ["concurrent 1.0", "spectre 0.8", "sys 1.0", "web 1.0"]
  }
}
