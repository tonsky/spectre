package fan.spectre;

import fan.sys.*;
import java.nio.*;
import java.nio.channels.*;

public class CircularBufTestPeer {
  public static CircularBufTestPeer make(CircularBufTest fan) { return new CircularBufTestPeer(); }
  public CircularBufTestPeer() {}
  
  public void testCircularBuffer(CircularBufTest fan) {
    CircularByteBuffer ub = new CircularByteBuffer(5);
    ub.push((byte)'a');
    ub.push((byte)'b');
    ub.push((byte)'c');
    ub.push((byte)'d');
    fan.verifyEq((char)ub.pop(), 'a'); // simple pop
    Buf b = Buf.make(1); // also will check how this buffers grow
    fan.verifyEq(ub.pipeTo(b, 2), 2); // simple pipeTo
    fan.verifyEq(b.seek(0).readAllStr(), "bc");
    
    fan.verifyEq(ub._b, 3); // check inner state of _b
    fan.verifyEq(ub._e, 4); // check inner state of _e
    ub.push((byte)'e');
    fan.verifyEq(ub._e, 0); // check _e crossing _buf.lenght
    ub.push((byte)'f'); // push across _buf.length
    fan.verifyEq(ub._e, 1);
    ub.push((byte)'g');
    fan.verifyEq(ub._b, 3);
    fan.verifyEq(ub._e, 2);
    
    b.clear();
    fan.verifyEq(ub.pipeTo(b, 5), 4); // pipeTo across _buf.length,
                                      // and with not enough data in ub
    fan.verifyEq(b.seek(0).readAllStr(), "defg");
    
    boolean thrown = false;
    try { ub.pop(); } // BufferUnderflow
    catch (BufferUnderflowException e) { thrown = true; }
    fan.verify(thrown, "Expected BufferUnderflowException, but got nothing");

    fan.verifyEq(ub.size(), 0); // simple size    
    ub.push((byte)'2');
    fan.verifyEq(ub.size(), 1);
    ub.push((byte)'3');
    fan.verifyEq(ub.size(), 2);
    ub.push((byte)'4');
    fan.verifyEq(ub.size(), 3);
    ub.push((byte)'0'); // push accros _buf.lenth
    fan.verifyEq(ub.size(), 4); // size across _buf.length
    
    thrown = false;
    try { ub.push((byte)'1'); } // BufferOverflow
    catch (BufferOverflowException e) { thrown = true; }
    fan.verify(thrown, "Expected BufferOverflowException, but got nothing");
    
    fan.verifyEq((char)ub.pop(), '2');
    fan.verifyEq((char)ub.pop(), '3');
    fan.verifyEq((char)ub.pop(), '4');
    fan.verifyEq((char)ub.pop(), '0'); // pop accros _buf.lenth
    fan.verifyEq(ub.size(), 0);
    fan.verifyEq(ub._b, 1); // check inner state of _b
    fan.verifyEq(ub._e, 1); // check inner state of _e
  }
}