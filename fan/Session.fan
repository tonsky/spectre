
using concurrent

// TODO think about some way to keep session constant 
// because it is passed to Actors through serialization
@Serializable
class Session {
  Str? id
  
  **
  ** Application name/value pairs which are persisted
  ** between HTTP requests.  The values stored in this
  ** map must be serializable.
  **
  Str:Obj? map := [:] 
  
  Bool isModified := false
  DateTime lastAccessed := DateTime.now

  new make(|This| f) { f.call(this) }
  
  @Operator
  Obj? get(Str name, Obj? def := null) { map.get(name, def) }

  @Operator
  Void set(Str name, Obj? val) { map[name] = val; isModified = true }

  **
  ** Delete this web session which clears both the user
  ** agent cookie and the server side session instance.
  **
  Void delete() {
    map = [:]
    isModified = true
  }
  
  override Str toStr() { "$map" }
}

// TODO some cleanup of expired sessions
abstract class SessionStore {
  virtual Duration? maxSessionAge := Duration.fromStr("14day")
  
  **
  ** Is called in SessionTurtle if session was modified. Should return data
  ** to store in cookie (e.g. session key).
  **
  abstract Str? save(Session session)

  **
  ** Is called in SessionTurtle before dispatching later. 
  ** Data stored in cookie is passed to this method (e.g. session key), or
  ** null if the client doesn't have session cookie yet.
  **
  abstract Session load(Str? cookieData)  
}


class MemorySessionStore : SessionStore {
  static const ActorPool actorPool := ActorPool()
  static const Actor actor := Actor(actorPool) |msg| { receive(msg) }
  
  virtual Str newSessionId() {
    return Uuid().toStr //TODO is it both effective and secure?
  }
  
  override Session load(Str? sessionId) {    
    Session? stored
    if (sessionId != null)
      stored = actor.send(sessionId).get

    if (sessionId == null   // no session
     || stored == null      // or sessionId has no data stored
     || DateTime.now.minusDateTime(stored.lastAccessed) > maxSessionAge) // or it has expired   
    {
       stored = Session { id = newSessionId }
    }
    
    return stored
  }
  
  override Str? save(Session session) {
    if (session.map.isEmpty) {
      delete(session)
      return null
    }
    
    actor.send(session).get
    return session.id
  }
  
  Void delete(Session session) {
    actor.send(["id": session.id]).get
  }
  
  static Obj? receive(Obj? msg) {
    [Str:Session]? sessions := Actor.locals["spectre.sessions"]
    if (sessions == null) Actor.locals["spectre.sessions"] = sessions = Str:Session[:]
    
    if (msg is Str) { // get
      sessionId := msg as Str
      return sessions[sessionId]
    }
    
    if (msg is Session) { // save
      session := (msg as Session)
      sessions[session.id] = session
      return msg
    }
    
    if (msg is Map) { // delete then
      sessionId := (msg as [Str:Str])["id"]
      return sessions.remove(sessionId)
    }
    
    throw ArgErr("Unknown message $msg")
  }
}

class SessionTurtle : Middleware {
  SessionStore sessionStore
  
  Str cookieName := "__spectre_session"
  Str contextAttrName := "session"  
  
  new make(Turtle child, |This->|? f := null) : super(child) { f?.call(this) }
  
  override Void before(Req req) {
    cookieData := loadCookieData(req)
    Session session := sessionStore.load(cookieData)
    req.context[contextAttrName] = session
  }
  
  override Res? after(Req req, Res? res) {
    Session session := req.context[contextAttrName]
    if(session.isModified) {
      Str? updatedCookieData := sessionStore.save(session)
      if (null == updatedCookieData)
        res.deleteCookie(cookieName)
      else
        saveCookie(updatedCookieData, res)
    }
    return res
  }
  
  virtual Str? loadCookieData(Req req) {
    encodedCookieData := req.cookies[cookieName]
    return encodedCookieData == null ? null : decode(encodedCookieData)
  }
  
  virtual Str decode(Str encoded) {
    return encoded//FIXME check string signature
  }
  
  virtual Void saveCookie(Str data, Res res) {
    encoded := encode(data)
    res.setCookie(Cookie { name = cookieName; val = encoded; maxAge = sessionStore.maxSessionAge } )
  }
  
  virtual Str encode(Str decoded) {
    return decoded//FIXME sign string
  }
}
