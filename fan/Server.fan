#! /usr/bin/env fan

using util
using wisp

class Server : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  @Arg { help = "path to app dir (must contains build.fan and spectre::App implementation)" }
  File? appDir
  
  override Int run() {
    return runServices([ WispService { it.port = this.port; root = AppReloadMod.make(appDir) } ])
  }
}
