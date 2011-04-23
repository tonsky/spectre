
using concurrent
using spectre

class SpectreWebapp : Settings {
  const ActorPool pool := ActorPool()
  
  override Bool debug := false
  
  new make(Str:Obj? params) : super(params) {
    staticFiles := Router {
      ["/static/*", StaticView(appDir + `static/`)],
      ["/i/*", StaticView(appDir + `static/i/`)],
      ["/favicon.ico", StaticView(appDir + `static/i/favicon.gif`)]
    }
    
    routes = includeApp(Router { ["/", IndexPage#index], })
            + includeApp(RoutingApp(), "/routing/")
            + includeApp(CookiesApp(), "/cookies/")
            + includeApp(SessionsApp(), "/sessions/")
            + includeApp(MessagesApp(), "/messages/")
            + includeApp(FormsApp(), "/forms/")
            + includeApp(Router {["/web_sockets/", ToTemplate("web_sockets.html")],}, "/web_sockets/")
            + includeApp(Router {["/broken/", BrokenView#err],}, "/broken/")
            + Router {["/inline/", |Bool debug->Res| { Res("Debug is $debug") }],}
            + staticFiles

    middlewares = [
      SessionMiddleware { sessionStore = InmemorySessionStore { maxSessionAge = 5sec; cleanupPeriod = 3sec }},
      MessageMiddleware(SessionMessageStore())
    ]

    renderer = MustacheRenderer([appDir + `templates/`])
  }
  
  Turtle includeApp(Turtle app, Str? appHref := null) {
    [Str:Obj?][] apps := [["href": "/routing/", "title": "Routing"],
                          ["href": "/cookies/", "title": "Cookies"], 
                          ["href": "/sessions/", "title": "Sessions"],
                          ["href": "/forms/", "title": "Forms"],
                          ["href": "/messages/", "title": "Messages"],
                          ["href": "/web_sockets/", "title": "Web sockets"],
                          ["href": "/404/", "title": "404"],
                          ["href": "/broken/", "title": "Error reporting"]]
    if (appHref != null) {
      current := apps.find { it["href"] == appHref }
      current?.set("is_current", true)
    }
    return TemplateContextMiddleware(["apps": apps, "current_app_title": "Demo application"]).wrap(app)
  }
  
  override WsProcessor? wsProcessor(WsHandshakeReq req) {
    if (req.uri.pathStr == "/") return SpectreWsProcessor(pool)
    else throw Err("Unknown path ${req.uri.pathStr}")
  }
}

class IndexPage {
  Res index(Req req, Bool debug) { TemplateRes("index.html", ["isDebugOn": debug]) }
}

class BrokenView {
  Res err() { throw Err.make("Hi there!") }
}

const class SpectreWsProcessor : WsActor {
  new make(ActorPool pool) : super(pool) {}
  
  // synchronous processing
  override Void onReady(WsConn conn) {
    conn.writeStr("I’m listening to you...")
    Buf? data := conn.read() // first message to be processed here, all the rest to be received asynchronously
    if (data == null) { conn.close; return }
    conn.writeStr("What do you mean “${data.readAllStr}?”")
    
    sendLater(0.5sec) |->|{ conn.writeStr("Hello!?") }
    sendLater(1sec)   |->|{ conn.writeStr("Who is it?") }
    sendLater(2sec)   |->|{ conn.writeStr("I’m going to hang up the phone!") }
    sendLater(3sec)   |->|{ conn.writeStr("Hanging up, bye!"); conn.close }
  }

  // asynchronous processing
  override Void asyncOnMsg(WsConn conn, Buf msg) {
    conn.writeStr("Is it you just saying “" + msg.readAllStr + "?”")
  }
}

class TemplateContextMiddleware : Middleware {
  [Str:Obj?] map
  new make([Str:Obj?] map) { this.map = map }
  
  override Res? safeAfter(Req req, Res res) { 
    if (res is TemplateRes)
      (res as TemplateRes).context.addAll(map)
    return res
  }
}

