
**
** Session provides a name/value map associated with
** a specific browser "connection" to the web server.
** You can inject session to your view as 'Session session' view arg.  
**
class Session {
  **
  ** This is a map of values stored in the current session.  Note that this
  ** field will usually be read-only, use `set` to set/change value in session.
  ** 
  Str:Obj? map
 
  @Operator
  virtual Obj? get(Str k) { map[k] }
  
  @Operator
  virtual This set(Str k, Obj? v) { map[k] = v; return this }

  **
  ** Clean up session and remove session cookie
  ** 
  virtual Void delete() { map = [:] }
  
  new make(|This|? f) { f?.call(this) }
  override Str toStr() { map.toStr }
}

**
** Read session from `sessionStore` and set in into 'req.context["session"]'.
** All children turtles and views can access session from 'context' or inject
** it into arguments as 'Session session' (views).  To change value in session
** use 'session[k] = v'. All changes made to session after this middleware returns
** from `dispatch` will not be stored.
** 
class SessionMiddleware : Middleware {
  **
  ** Must be initialized in constructor
  ** 
  SessionStore sessionStore

  // various session cookie attributes
  Str cookieName := "__spectre_session"
  Str? cookieDomain
  Str? cookiePath
  Bool? cookieSecure
  
  **
  ** Name to store session in context
  **   
  Str contextAttrName := "session"
  
  **
  ** If set to 'true', cookie will be refreshed each time session is accessed
  ** 
  Bool saveEveryRequest := false
  
  new make(|This|? f := null) { f?.call(this) }

  override Res? dispatch(Req req) {
    cookieData := loadCookieData(req)
    Session session := sessionStore.load(cookieData)
    
    Res? res := child.dispatch(req.dupWith([contextAttrName: session]))
    if (res != null) {
      Str? updatedCookieData := sessionStore.save(session, cookieData, saveEveryRequest)
      if (null == updatedCookieData) {
        if (cookieData != null)
          res.deleteCookie(cookieName)
      } else {
        if (cookieData != updatedCookieData || saveEveryRequest)
          saveCookie(updatedCookieData, res)
      }
    }

    return res
  }
  
  **
  ** Load session cookie data and decode it
  ** 
  virtual Str? loadCookieData(Req req) {
    encodedCookieData := req.cookies[cookieName]
    return encodedCookieData == null ? null : decode(encodedCookieData)
  }

  **
  ** Decode untrusted cookie data from client
  ** 
  virtual Str decode(Str encoded) {
    return encoded//FIXME check string signature
  }

  **
  ** Refresh session cookie
  ** 
  virtual Void saveCookie(Str data, Res res) {
    encoded := encode(data)
    res.setCookie(Cookie { 
      name = cookieName
      val = encoded
      maxAge = sessionStore.maxSessionAge
      domain = cookieDomain
      if (cookiePath != null) path = cookiePath
      if (cookieSecure != null) secure = cookieSecure
    })
  }
  
  **
  ** Encode cookie data to be stored on the client securely
  ** 
  virtual Str encode(Str decoded) {
    return decoded//FIXME sign string
  }
}

**
** Base class for session storing strategies
** 
abstract class SessionStore {
  **
  ** Sessions will expire after this period passed. If set to null,
  ** sessions will last until browser window close.
  ** 
  virtual Duration? maxSessionAge := Duration.fromStr("14day")
  
  **
  ** Interval store should run cleaner (removing of expired sessions) on itself.
  ** 
  virtual Duration? cleanupPeriod := Duration.fromStr("1hr")

  // TODO should sessionId be specified from view?
  virtual Str newSessionId() {
    return Uuid().toStr //TODO is it both effective and secure?
  }

  **
  ** Is called in SessionMiddleware before request dispatching starts. 
  ** Data stored in cookie is passed to this method (e.g. session key), or
  ** null if the client doesn't have session cookie yet.
  ** Session returned by this method will be made avaliable to subsequent views.
  **
  abstract Session load(Str? cookieData)
  
  **
  ** This method is called after request dispatch. It should perform session
  ** saving (if changed) and return data to store in cookie (e.g. session key), 
  ** or null if cookie should be removed
  **
  abstract Str? save(Session session, Str? oldCookieData, Bool forceSave := true)
}
