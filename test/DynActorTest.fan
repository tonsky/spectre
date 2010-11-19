
using concurrent

const class TestDynActor : DynActor {
  new make(ActorPool pool) : super(pool) {}
  
  protected Str _method1(Str param1, Str param2, Int param3 := 0) {
    return "[$param1, $param2, $param3]"
  }
  
  protected Void _method2() {
    x := 1 + 2
  }
  
  static Int _staticMethod(Int x) {
    return x + 55
  }
  
  protected SerializableArg _serializationTest(ConstArg? ca := null, 
    SerializableArg? sa := null, NotSerializableArg? nsa := null) {
    if (ca !== DynActorTest.staticConstArg)
      throw ConstWasSerializedErr("Constant argument 'ca' was not passed by reference")
    return SerializableArg { x = 25; y = sa?.y + " passed" }
  }
  
  protected Void _unsafePassing(Unsafe sa) {
    if (sa.val !== DynActorTest.staticSerializableArgUnsafe.val)
      throw Err("Unsafe argument was not passed by reference")
  }
  
  protected Void _unsafeUnwrapping(SerializableArg sa) {
    if (sa !== DynActorTest.staticSerializableArgUnsafe.val)
      throw ConstWasSerializedErr("Unsafe argument was not passed by reference")
  }
}

const class ConstWasSerializedErr : Err { new make(Str msg) : super(msg) {} }

@Serializable
class SerializableArg {
  Int x := 1
  Str y := "2"
}

const class ConstArg {
  const Int z := 100
  const Str s := "ttt"
}

class NotSerializableArg {
  Int x := 1
  Str y := "2"
}

class DynActorTest : Test {
  static const ConstArg staticConstArg := ConstArg()
  static const Unsafe staticSerializableArgUnsafe := Unsafe(SerializableArg { x := 5; y := "xxx" })

  Void testSerialization() {
    a := TestDynActor(ActorPool())
    SerializableArg res := a->sendSerializationTest(staticConstArg, SerializableArg { y = "test" })
    verifyEq(res.x, 25)
    verifyEq(res.y, "test passed")
    
    verifyErr(ConstWasSerializedErr#) { a->sendSerializationTest(ConstArg(), SerializableArg()) }
    
    verifyErr(IOErr#) { a->sendSerializationTest(ConstArg(), SerializableArg(), NotSerializableArg()) }
    
    a->sendUnsafePassing(staticSerializableArgUnsafe)
    a->sendUnsafeUnwrapping(staticSerializableArgUnsafe)
    verifyErr(ConstWasSerializedErr#) { a->sendUnsafeUnwrapping(staticSerializableArgUnsafe.val) }
  }
  
  Void testMethodName() {
    a := DynActor(ActorPool())
    verifyEq(a.toMethodName("sendSomeName"), "_someName")
    verifyEq(a.toMethodName("sendSomeNameNoWait"), "_someName")
    verifyEq(a.toMethodName("sendSend"), "_send")
    verifyEq(a.toMethodName("sendNoWaitNoWait"), "_noWait")
    verifyEq(a.toMethodName("sendNoWait"), "_")
    verifyEq(a.toMethodName("sendNoWaitName"), "_noWaitName")
    verifyEq(a.toMethodName("sendHELLO"), "_hELLO")
    verifyEq(a.toMethodName("sendA"), "_a")
    verifyEq(a.toMethodName("send"), "_")
  }
  
  Void testMethodCalls() {
    a := TestDynActor(ActorPool())
    verifyEq(a->sendMethod1("X", "y", 2), "[X, y, 2]")
    verifyEq(a->sendMethod1("X", "y"), "[X, y, 0]")
    verifyEq(a->sendMethod1NoWait("X", "y", 2).typeof, Future#)
    verifyEq(a->sendMethod2, null)
    verifyEq(a->sendMethod2NoWait.typeof, Future#)
    
    verifyEq(a->sendStaticMethod(5), 60)
    verifyEq(a->sendStaticMethodNoWait(5).typeof, Future#)
    
    // required args are required
    verifyErr(ArgErr#) { a->sendMethod1 }
    verifyErr(ArgErr#) { a->sendMethod1("1", 2, 3) }
    verifyErr(ArgErr#) { a->sendStaticMethod }
    
    a->sendMethod1NoWait
    a->sendStaticMethodNoWait
  }
}
