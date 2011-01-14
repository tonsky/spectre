using util

// SPECTRE
class SpectrePerfTest : AbstractMain {
  @Opt { help = "http port" }
  Int port := 8080

  override Int run() {
    return runServices([ WebServer { 
      it.port = this.port
      protocols = [
        HttpProtocol { HttpRes(200, 
                               [["Content-Type", "text/plain; charset=utf8"]],
                               "Hello world #4".toBuf) }
      ]
    } ])
  }
}

// WISP
//using wisp
//
//class WispPerfTest : AbstractMain {
//  @Opt { help = "http port" }
//  Int port := 8080
//
//  override Int run() {
//    wisp := WispService { it.port = this.port;  it.root = HelloMod(); }
//    return runServices([wisp])
//  }
//}
//
//const class HelloMod : WebMod {
//  override Void onGet() {
//    res.headers["Content-Type"] = "text/plain; charset=utf-8"
//    res.out.print("hello world #4")
//  }
//}

