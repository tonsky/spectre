package fan.spectre;

import fan.sys.*;

import java.nio.*;
import java.nio.channels.*;

public class ChInBlockingTestPeer {
  public static ChInBlockingTestPeer make(ChInBlockingTest fan) { return new ChInBlockingTestPeer(); }
  public ChInBlockingTestPeer() {}
  
  public void testR(ChInBlockingTest fan) {
    for (ChannelInStream in: new ChannelInStream[] {
      new ChannelInStream(new ChMock(new Object[] {"a", "", "", "bcd", new byte[]{(byte)0xFF}}, true), 10, true),
      new ChannelInStream(new ChMock(new Object[] {"a", "", "", "bcd", new byte[]{(byte)0xFF}}, true), 2, true)
    }) {
      fan.verifyEq((char)in.r(), 'a'); // simple read
      fan.verifyEq((char)in.r(), 'b'); // chunk > buffer, partially read
      fan.verifyEq((char)in.r(), 'c');
      fan.verifyEq((char)in.r(), 'd'); // chunk > buffer, second read
      fan.verifyEq(in.r(), 0xFF); // third chunk
      fan.verifyEq(in.r(), -1); // eof
      fan.verify(!in._ch.isOpen());
    }
  }
  
  public void testReadBuf(ChInBlockingTest fan) {
    ChannelInStream in = new ChannelInStream(new ChMock(new String[] {"ab", "cdefg", "", "", "x"}, true), 3, true);
    Buf b = Buf.make(1);
    fan.verifyEq(in.readBuf(b, 3), 2L); // bigger than chunk
    fan.verifyEq(b.seek(0).readAllStr(), "ab");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 4), 3L); // bigger than internal buf
    fan.verifyEq(b.seek(0).readAllStr(), "cde");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 2), 2L); // rest of the chunk
    fan.verifyEq(b.seek(0).readAllStr(), "fg");
    b.clear();

    fan.verifyEq(in.readBuf(b, 5), 1L); // rest of data in socket, eof should not be reported here
    fan.verifyEq(b.seek(0).readAllStr(), "x");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 1), null); // eof
    fan.verify(!in._ch.isOpen());
  }
  
  public void testUnread(ChInBlockingTest fan) {
    ChannelInStream in = new ChannelInStream(new ChMock(new String[] {"abc", "def"}, true), 3, true);
    in.unread('0');
    in.unread('1');
    in.unread('2');
    Buf b = Buf.make(1);
    fan.verifyEq(in.readBuf(b, 5), 5L); // unread doesn’t depend on buf size
    fan.verifyEq(b.seek(0).readAllStr(), "012ab");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 5), 1L); // rest of buf
    fan.verifyEq(b.seek(0).readAllStr(), "c");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 5), 3L); // last buf
    fan.verifyEq(b.seek(0).readAllStr(), "def");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 5), null); // eof
    fan.verify(!in._ch.isOpen());
  }
  
  public void testSkip(ChInBlockingTest fan) {
    ChannelInStream in = new ChannelInStream(new ChMock(new String[] {"a", "", "", "bcdef", "x"}, true), 3, true);
    fan.verifyEq(in.skip(1), 1L);
    fan.verifyEq(in.skip(4), 3L); // more than buf size
    fan.verifyEq(in.skip(4), 2L); // rest of chunk
    fan.verifyEq(in.skip(4), 1L); // last chunk
    fan.verifyEq(in.skip(4), -1L); // eof
  }
}