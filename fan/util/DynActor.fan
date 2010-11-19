using concurrent

const class SerializedWrapper {
  const Str content
  new make(Obj obj) {
    sb := StrBuf()
    sb.out.writeObj(obj)
    content = sb.toStr
  }  
  Obj val() { content.in.readObj }
}

const class DynActorCommand {
  const Method method
  const Obj?[] args
  
  new make(Method m, Obj?[] args := [,]) {
    this.method = m
    this.args = args.map { it.isImmutable ? it : SerializedWrapper(it) }
  }
  
  Obj? invoke(Actor? instance := null) {
    params := method.func.params
    off := method.isStatic ? 0 : 1
    deserializedArgs := args.map |arg, idx| {
      if (arg is SerializedWrapper // unwrapping serialized field 
          || (arg is Unsafe && params[idx+off].type != Unsafe#)) // trying Unsafe unwrap
        return arg->val
      else
        return arg
    }
    
    return method.isStatic ? method.callList(deserializedArgs) 
      : method.callOn(instance, deserializedArgs)
  }
}

const class DynActor : Actor {
  new make(ActorPool pool) : super(pool) {}
  
  override Obj? receive(Obj? msg) {
    return (msg as DynActorCommand).invoke(this)
  }
  
  virtual Str toMethodName(Str trappedName) {
    if (!trappedName.startsWith("send"))
      throw UnknownSlotErr("Cannot call '$trappedName'. To call underscore methods, call them as 'send<MethodName>[NoWait]'")
    trappedName = trappedName[4..-1] // removing 'send'
    if (trappedName.endsWith("NoWait"))
      trappedName = trappedName[0..-7] // removing 'NoWait'
    return "_" + trappedName.decapitalize
  }
  
  override Obj? trap(Str name, Obj?[]? args) {
    Str methodName := toMethodName(name)
    Method method := this.typeof.method(methodName)
    
    future := this.send(DynActorCommand(method, args))
    return name.endsWith("NoWait") ? future : future.get
  }
}