using concurrent

**
** Non-blocking IO actor. To start, call `sendRegister` with sockets from which to start.
** When started, this actor will loop infinitely.
**
const class SelActor: Actor {
  protected Log log() { Log.get("spectre") } 
  new make(ActorPool pool) : super.makeCoalescing(pool, SelActorMsg#key.func, SelActorMsg#coalesce.func) {}
  
  ** Main method to set sockets to watch by this selector
  ** Send array of `spectre::TcpSocket` and `spectre::TcpListrener` here.
  ** When data become avaliable, thier 'acceptReady' or 'readReady' callbacks
  ** will be called in `SelActor` thread.
  Future sendRegister(Obj[] sockets) {
    f := this.send(SelActorMsg(sockets))
    this._wakeup() // in caller’s thread
    return f
  }
  
  override Obj? receive(Obj? _val) {
    try {
      val := _val as SelActorMsg
      val.sockets.each { this._register(it) }
      this._select()
      this.send(SelActorMsg([,])) // looping ourself
      return null
    } catch (Err e) {
      log.err("Error in SelActor#receive", e)
      throw e
    }
  }
  
  Void stop() {
    // FIXME implement
  }
  
  protected native Void _register(Obj s)
  protected native Void _unregister(Obj s)
  
  protected native Void _select()
  protected native Void _wakeup()
}

**
** All this messages will always coalesce to a single message
**
const class SelActorMsg {
  const Unsafe _sockets
  Obj[] sockets() { _sockets.val }
  new make(Obj[] sockets) { this._sockets = Unsafe(sockets.ro) }
  
  static Int key() { 0 }
  static SelActorMsg coalesce(SelActorMsg orig, SelActorMsg inc) {
    SelActorMsg([,].addAll(orig.sockets).addAll(inc.sockets).unique)
  }
  
  override Str toStr() { sockets.toStr }
}
