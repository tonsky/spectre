using spectre

class NewappnameApp : Settings {
  new make(Str:Obj? params) : super(params) {
    routes = Router {
      ["/", IndexPage#index],
      ["/s/*", StaticView(appDir + `static/`)],
      ["/favicon.gif", StaticView(appDir + `static/favicon.gif`)]
    }
  }
}

class IndexPage {
  Res index() {
    TemplateRes("index.html", ["msg": "Welcome to Spectre", "app": "newappname"])
  }
}