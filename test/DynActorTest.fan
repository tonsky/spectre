
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
    
    // see how const args and serializable args are passed
    SerializableArg res := a->sendSerializationTest(staticConstArg, SerializableArg { y = "test" })->get
    verifyEq(res.x, 25)
    verifyEq(res.y, "test passed")
    // check that prev test is is actually testing smth
    verifyErr(ConstWasSerializedErr#) { a->sendSerializationTest(ConstArg(), SerializableArg())->get }
    
    // see if not-serializable arg will raise error
    verifyErr(IOErr#) { a->sendSerializationTest(ConstArg(), SerializableArg(), NotSerializableArg()) }
    
    // see in unsafe is passed by reference
    a->sendUnsafePassing(staticSerializableArgUnsafe)->get
    // see in unsafe is correctly unwrapped
    a->sendUnsafeUnwrapping(staticSerializableArgUnsafe)->get
    // check that two prev test are actually testing smth
    verifyErr(ConstWasSerializedErr#) { a->sendUnsafeUnwrapping(staticSerializableArgUnsafe.val)->get }
  }
  
  Void testMethodName() {
    a := DynActor(ActorPool())
    verifyEq(a.toMethodName("sendSomeName"), "_someName")
    verifyEq(a.toMethodName("sendSomeNameNoWait"), "_someNameNoWait")
    verifyEq(a.toMethodName("sendSend"), "_send")
    verifyEq(a.toMethodName("sendHELLO"), "_hELLO")
    verifyEq(a.toMethodName("sendA"), "_a")
    verifyEq(a.toMethodName("send"), "_")
  }
  
  Void testMethodCalls() {
    a := TestDynActor(ActorPool())

    // passing args
    verifyEq(a->sendMethod1("X", "y", 2).typeof, Future#)
    verifyEq(a->sendMethod1("X", "y", 2)->get, "[X, y, 2]")
    // default args
    verifyEq(a->sendMethod1("X", "y")->get, "[X, y, 0]")
    // no args, no return value
    verifyEq(a->sendMethod2.typeof, Future#)
    verifyEq(a->sendMethod2->get, null)
    
    // static
    verifyEq(a->sendStaticMethod(5).typeof, Future#)
    verifyEq(a->sendStaticMethod(5)->get, 60)
    
    // required args are required
    verifyErr(ArgErr#) { a->sendMethod1->get }
    verifyErr(ArgErr#) { a->sendMethod1("1", 2, 3)->get }
    verifyErr(ArgErr#) { a->sendStaticMethod->get }
    
    // if result is not retrieved, no exception is thrown
    a->sendMethod1
    a->sendStaticMethod
  }
}
