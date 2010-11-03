#! /usr/bin/env fan

using concurrent
using util
using web
using wisp

class WispServer : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  @Arg { help = "path to app dir (must contains build.fan and spectre::App implementation)" }
  File? appDir
  
  override Int run() {
    return runServices([ WispService { it.port = this.port; root = AppReloadMod.make(appDir) } ])
  }
}

const class AppReloadMod : WebMod {
  const Actor watchPodActor
  const File podDir
  
  new make(File podDir) {
    watchPodActor = WatchPodActor.make(ActorPool(), podDir)
    this.podDir = podDir
  }
  
  override Void onService() {
    App? app := watchPodActor.send(null).get
    Actor.locals["spectre.app"] = app
    Actor.locals["spectre.app_dir"] = podDir
    //FIXME store this value somewhere
    RoutingMod.make(app.routes).onService
  }
}

const class RoutingMod : WebMod, Router {
  override const Binding[] bindings := Binding[,]

  new make(Binding[] bindings) {
    if (bindings.isEmpty) throw ArgErr("RoutingMod.bindings cannot be empty")
    this.bindings = bindings
  }

  override Void onService() {
    HttpRes result := process(WebletRequest.make)
    writeResponse(result)
  }
  
  Void writeResponse(HttpRes response) {
    res.headers.addAll(response.headers)
    res.statusCode = response.statusCode
    res.out.charset = response.charset
    response.writeBody(Env.cur.out)
    response.writeBody(res.out)
    res.done
  }
}
