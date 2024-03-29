using concurrent

**
** Type-safe, handy message passing for `Actor`s.
** 
** All methods in this actor started from '_' (underscore) became *message
** acceptors*. They can have any number of arguments, any return values — 
** just as usual methods, but can accept messages.
**
** To define a *message acceptor*, you write a method:
**  
**   protected Str _onMessage(Int arg1, Str agr2, Obj? arg3 := null) {
**     ... // message body here
**   }
** 
** To send message to this acceptor:
** 
**   actor->sendOnMessage(1, "arg2 value", Unsafe("arg3 value"))
** 
** (Note that you should add 'send', remove underscore and capitalize first letter).
** 
** All 'send*' methods return `Future`. To get result from message acceptor use
** `Future.get` (execution will be blocked until acceptor completion):
** 
**   Str res := actor->sendOnMessage(1, "2")->get
** 
** You can pass/return only serializable, const or `Unsafe` args 
** to/from message accept methods. `Unsafe` args can be automatically 
** unwrapped in message acceptor’s body:
**
**   // on send, you wrap not-const args in Unsafe
**   actor->sendAction(Unsafe(notConstArgInstance))
**   
**   protected Str _action(NotConstArg arg1) {
**     // here you accept automatically unwrapped instance
**   }
** 
** It’s also possible to send const closures with no arguments to DynActor:
** 
**   const Int x := 1
**   ...
**   actor.send |->Int| { this.x + 2 } 
** 
const class DynActor : Actor {
  virtual protected Log log() { Log.get("spectre.DynActor") }
  new make(ActorPool pool, |This|? f := null) : super(pool) { f?.call(this) }
  
  override Obj? receive(Obj? msg) {
    try {
      if (msg is Unsafe)
        msg = (msg as Unsafe).val
    
      if (msg is DynActorCommand)
        return (msg as DynActorCommand).invoke(this)
      else if (msg is Func)
        return (msg as Func).call
      else
        throw UnsupportedErr("You should pass either DynActorCommand or Func")
    } catch(Err e) {
      log.err("Error in actor $this", e)
      throw e
    }
  }
  
  virtual Str toMethodName(Str trappedName) {
    if (!trappedName.startsWith("send"))
      throw UnknownSlotErr("Cannot call '$trappedName'. To call underscore methods, call them as 'send<MethodName>'")
    trappedName = trappedName[4..-1] // removing 'send'
    return "_" + trappedName.decapitalize
  }
  
  override Obj? trap(Str name, Obj?[]? args := null) {
    Str methodName := toMethodName(name)
    Method method := this.typeof.method(methodName, true) //checked
    return this.send(DynActorCommand(method, args))
  }
}

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
  
  new make(Method m, Obj?[]? args := [,]) {
    this.method = m
    this.args = (args?:[,]).map { it.isImmutable ? it : SerializedWrapper(it) }
  }
  
  Obj? invoke(Obj? instance := null) {
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