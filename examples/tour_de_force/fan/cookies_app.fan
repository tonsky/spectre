using spectre

class CookiesApp : Router {
  new make() : super() {
    add(["/cookies/", CookiesViews#index])
    add(["/cookies/set-cookie/", CookiesViews#setCookie])
    add(["/cookies/delete-cookie/", CookiesViews#deleteCookie])      
  }
}

class CookiesViews {
  virtual Res index(Req req) {
    return TemplateRes("cookies.html", ["cookies": req.cookies.map |v,k| { ["name": k, "value": v]  }.vals])
  }
  
  virtual Res setCookie(Req req) {
    res := ResRedirect(`../`)
      .setCookie(Cookie { 
        name = req.get["cookie-name"]
        val = req.get["cookie-value"]
        maxAge = Duration.fromStr("1day")
        domain = req.get["cookie-domain"] == "" ? null : req.get["cookie-domain"]
      })
      .setCookie(Cookie { name = "secondcookie"; val = "b"; maxAge = Duration.fromStr("5sec")})
      .setCookie(Cookie { name = "thirdcookie"; val = "c"; maxAge = Duration.fromStr("15sec") })
    return res
  }
  
  virtual Res deleteCookie(Req req) {
    return ResRedirect(`../`).deleteCookie(req.get["cookie-name"])
  }
}