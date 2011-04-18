using spectre

const class Smth {
  const Int smth := 0
  override Str toStr() {
    return "<Smth: $smth>"
  }
}

class SessionsApp : Router {
  new make() : super() {
    add(["/sessions/", SessionsViews#index])
    add(["/sessions/init-session/", SessionsViews#initSession])
    add(["/sessions/change-session/", SessionsViews#changeSession])
    add(["/sessions/clear-session/", SessionsViews#clearSession])
  }
}

class SessionsViews {
  virtual Res index(Session session) {
    return TemplateRes("basic/basic.html", 
      ["content": "sessions.html", "session": session.map.map |v,k| { ["name": k, "value": v] }.vals ])
  }
  
  Res initSession(Req req) {
    Session session := req.context("session")
    session["test"] = "test_value"
    session["const"] = Smth()
    
    return ResRedirect(`../`)
  }
  
  Res changeSession(Req req, Session session) {
    session.set("test", "changed_value")
    session.set("const", null)
    session.set("added", null)
    
    return ResRedirect(`../`)
  }
  
  Res clearSession(Req req, Session session) {
    session.delete
    return ResRedirect(`../`)
  }
}