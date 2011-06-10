package fan.spectre;

import fan.sys.*;
import java.io.*;
import java.nio.*;
import java.nio.channels.*;

class ChannelOutStream extends OutStream {
  public ByteBuffer _bb;
  public WritableByteChannel _ch;

  public ChannelOutStream(WritableByteChannel ch, int bufSize) {
    this._ch = ch;
    this._bb = ByteBuffer.allocate(bufSize);
  }

  public final OutStream write(long v) { return w((int)v); }
  public final OutStream w(int v) {
    _bb.put((byte)v);
    checkFlush();
    return this;
  }

  public final OutStream writeBuf(Buf buf) { return writeBuf(buf, buf.remaining()); }
  public OutStream writeBuf(Buf other, long n) {
    int len = (int) n;
    while (len > 0) {
      int amount = Math.min(len, _bb.remaining());
      other.pipeTo(_bb, amount);
      len -= amount;
      checkFlush();
    }
    return this;
  }

  public void checkFlush() {
    if (_bb.position() >= _bb.capacity())
      flush();
  }
  
  public OutStream flush() {
    try {
      _bb.flip();
      while(_bb.remaining() > 0) {
        if (!_ch.isOpen() || _ch.write(_bb) < 0) {
          close();
          break;
        }
      }
      _bb.clear();
      return this;
    } catch (IOException e) { 
      close();
      throw IOErr.make(e);
    }
  }

  public boolean close() {
    try {
      _ch.close();
      return true;
    } catch (IOException e) { return false; }
  }
}