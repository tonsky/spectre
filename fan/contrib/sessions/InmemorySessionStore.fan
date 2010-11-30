
using concurrent

**
** Store all session data in memory. Objects stored in session must be immutable.
** This session store is optimized for read, all session data are const objects,
** and `ImmutableSession` uses copy-on-write for 'session.map'.
** 
class InmemorySessionStore : SessionStore {
  internal static const InmemorySessionActor actor := InmemorySessionActor(ActorPool())
  
  new make(|This|? f := null) {
    f?.call(this)
    if (maxSessionAge != null && cleanupPeriod != null)
      actor->sendStartCleaning(maxSessionAge, cleanupPeriod)
  }
  
  override Session load(Str? sessionId) {
    if (sessionId != null) {
      [Str:Obj?]? stored := actor->sendLoad(sessionId, maxSessionAge)
      if (stored != null)
        return InmemorySession { map = stored }
    }
    
    return InmemorySession { map = [:].toImmutable }
  }
  
  override Str? save(Session session, Str? sessionId, Bool forceSave) {
    if (session.map.isEmpty) {
      if (sessionId != null)
        actor->sendDeleteNoWait(sessionId)
      return null
    } else {
      sessionId = sessionId ?: newSessionId
      if (isModified(session) || forceSave)
        actor->sendSaveNoWait(sessionId, session.map.toImmutable)
      return sessionId
    }
  }
  
  Bool isModified(Session session) { !session.map.isImmutable }
}

**
** Session implementation which uses copy-on-write for `map` slot.
** 
class InmemorySession : Session {
  new make(|This|? f): super(f) {}
  
  @Operator
  override This set(Str k, Obj? v) { map = map.rw; super.set(k, v); return this }
}

internal const class InmemorySessionInfo {
  const Str:Obj? map
  const DateTime lastModified
  
  new make(|This|? f) { f?.call(this) }
}

internal const class InmemorySessionActor : DynActor {
  new make(ActorPool pool) : super(pool) {}
  
  Str:InmemorySessionInfo sessions() {
    Actor.locals.getOrAdd("spectre.sessions2.session_actor") { Str:InmemorySessionInfo [:] }
  }
  
  protected [Str:Obj?]? _load(Str id, Duration? maxAge) {
    session := sessions[id]
    if (maxAge != null && session.lastModified.plus(maxAge) < DateTime.now) {
      sessions.remove(id)
      return null
    }
    return session.map
  }
  
  protected Void _save(Str id, Str:Obj? map) {
    sessions[id] = InmemorySessionInfo {
      it.map = map.toImmutable
      it.lastModified = DateTime.now
    }
  }

  protected Void _delete(Str id) {
    sessions.remove(id)
  }
  
  protected Void _startCleaning(Duration maxSessionAge, Duration cleanupPeriod) {
    if (Actor.locals["spectre.contrib.session.inmem_actor.cleaning_started"] != null)
      return
    Actor.locals["spectre.contrib.session.inmem_actor.cleaning_started"] = true
    this.sendLater(cleanupPeriod, DynActorCommand(#_cleanup, [maxSessionAge, cleanupPeriod]))
  }
  
  protected Void _cleanup(Duration maxSessionAge, Duration cleanupPeriod) {
    oldestAge := DateTime.now.minus(maxSessionAge)
    sessions.each |v, k| {
      if (v.lastModified < oldestAge)
        sessions.remove(k)
    }
    this.sendLater(cleanupPeriod, DynActorCommand(#_cleanup, [maxSessionAge, cleanupPeriod]))
  }
}
