
using concurrent

const class Cache : DynActor {
  internal Obj:Obj? values {
    get { Actor.locals.getOrAdd("spectre.cache") { Obj:Obj?[:] } }
    set { Actor.locals["spectre.cache"] = it }
  }
  
  new make(ActorPool pool) : super(pool) {}
  
  internal Obj? _getOrAdd(Obj key, |->Obj?| valGenerator) {
    Unsafe(values.getOrAdd(key, valGenerator))
  }
  
  Obj? getOrAdd(Obj key, |->Obj?| valGenerator) {
    Unsafe? res := this->sendGetOrAdd(key, Unsafe(valGenerator))->get
    return res?.val
  }
}
