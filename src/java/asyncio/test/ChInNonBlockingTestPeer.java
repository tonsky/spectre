package fan.spectre;

import fan.sys.*;

import java.nio.*;
import java.nio.channels.*;

public class ChInNonBlockingTestPeer {
  public static ChInNonBlockingTestPeer make(ChInNonBlockingTest fan) { return new ChInNonBlockingTestPeer(); }
  public ChInNonBlockingTestPeer() {}
  
  public void testR(ChInNonBlockingTest fan) {
    for (ChannelInStream in: new ChannelInStream[] {
      new ChannelInStream(new ChMock(new String[] {"a", "", "", "bcd", "x"}, false), 10, false),
      new ChannelInStream(new ChMock(new String[] {"a", "", "", "bcd", "x"}, false), 2, false)
    }) {
      fan.verifyEq((char)in.r(), 'a'); // simple read
      fan.verifyEq(in.r(), -2); // ‘no data yet’
      fan.verifyEq(in.r(), -2); // ‘no data yet’
      fan.verifyEq((char)in.r(), 'b'); // chunk > buffer, partially read
      fan.verifyEq((char)in.r(), 'c');
      fan.verifyEq((char)in.r(), 'd'); // chunk > buffer, second read
      fan.verifyEq((char)in.r(), 'x'); // third chunk
      fan.verifyEq(in.r(), -1); // eof
      fan.verify(!in._ch.isOpen());
    }
  }
  
  public void testReadBuf(ChInNonBlockingTest fan) {
    ChannelInStream in = new ChannelInStream(new ChMock(new String[] {"ab", "cdefg", "", "", "x"}, false), 3, false);
    Buf b = Buf.make(1);
    fan.verifyEq(in.readBuf(b, 3), 2L); // bigger than chunk
    fan.verifyEq(b.seek(0).readAllStr(), "ab");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 4), 4L); // bigger than internal buf
    fan.verifyEq(b.seek(0).readAllStr(), "cdef");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 1), 1L); // rest of the chunk
    fan.verifyEq(b.seek(0).readAllStr(), "g");
    b.clear();

    fan.verifyEq(in.readBuf(b, 5), 0L); // no data yet
    fan.verifyEq(in.readBuf(b, 5), 0L); // still no data yet

    fan.verifyEq(in.readBuf(b, 5), 1L); // rest of data in socket, eof should not be reported here
    fan.verifyEq(b.seek(0).readAllStr(), "x");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 1), null); // eof
    fan.verify(!in._ch.isOpen());
  }
  
  public void testUnread(ChInNonBlockingTest fan) {
    ChannelInStream in = new ChannelInStream(new ChMock(new String[] {"abcdefghijkl"}, false), 3, false);
    fan.verifyEq((char)in.r(), 'a'); // simple read
    fan.verifyEq((char)in.r(), 'b'); // simple read
    in.unread('0');
    fan.verifyEq((char)in.r(), '0'); // read unreaded
    fan.verifyEq((char)in.r(), 'c');
    in.unread('1');
    in.unread('2');
    in.unread('3');
    fan.verifyEq((char)in.r(), '1');
    fan.verifyEq((char)in.r(), '2');
    fan.verifyEq((char)in.r(), '3');
    fan.verifyEq((char)in.r(), 'd'); // read next buf from socket
    fan.verifyEq((char)in.r(), 'e');

    in.unread('4');
    Buf b = Buf.make(1);
    fan.verifyEq(in.readBuf(b, 5), 5L); // simple buf read
    fan.verifyEq(b.seek(0).readAllStr(), "4fghi");
    b.clear();
    
    in.unread('5');
    in.unread('6');
    in.unread('7');
    
    fan.verifyEq(in.readBuf(b, 1), 1L); // read unread only
    fan.verifyEq(b.seek(0).readAllStr(), "5");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 10), 5L); // read unread & read bigger than buf
    fan.verifyEq(b.seek(0).readAllStr(), "67jkl"); // we reach eof here
    b.clear();
    
    in.unread('8');
    in.unread('9');
    fan.verifyEq((char)in.r(), '8'); // reading from closed channel
    fan.verifyEq(in.readBuf(b, 10), 1L); // reading from closed channel
    fan.verifyEq(b.seek(0).readAllStr(), "9");
    b.clear();
    
    fan.verifyEq(in.readBuf(b, 5), null); // eof
    fan.verifyEq(in.r(), -1); // eof
    fan.verify(!in._ch.isOpen());
  }
  
  public void testSkip(ChInNonBlockingTest fan) {
    ChannelInStream in = new ChannelInStream(new ChMock(new String[] {"a", "", "", "bcdef", "x"}, false), 3, false);
    fan.verifyEq(in.skip(1), 1L);
    fan.verifyEq(in.skip(1), 0L); // no data
    fan.verifyEq(in.skip(1), 0L); // no data
    fan.verifyEq(in.skip(4), 4L); // more than buf size
    fan.verifyEq(in.skip(1), 1L); // rest of buf size
    fan.verifyEq(in.skip(4), 1L); // more than buf size
    fan.verifyEq(in.skip(4), -1L); // eof
  }
}