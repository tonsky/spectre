package fan.spectre;

import fan.sys.*;
import java.io.*;
import java.nio.*;
import java.nio.channels.*;

/**
 * This InStream works in two modes: blocking and non-blocking.
 * In non-blocking mode, it will repeat reading until end of current
 * data chunk. It’s possible to return no data read if there’s nothing
 * in socket right now. In non-blocking mode read always returns immediatly.
 *
 * In blocking mode, it will always try to read at least one byte. If there’s
 * no data right now, it will block until there’ll be something.
 *
 * **IMPORTANT** Underlying socket should be set to the same blocking mode as this stream.
 */

public class ChannelInStream extends InStream {
  public ByteBuffer _bb;
  public CircularByteBuffer _ub;
  public ReadableByteChannel _ch;
  public boolean _blocking;
  
  public ChannelInStream(ReadableByteChannel ch, int bufSize, boolean blocking) {
    this._ch = ch;
    this._bb = ByteBuffer.allocate(bufSize);
    this._bb.clear().flip(); // set to empty w/o data
    this._blocking = blocking;
  }

  public Long read() { 
    int r = r();
    return r >= 0 ? Long.valueOf(r) : r == -1 ? null : Long.valueOf(-2);
  }

  /**
   * @return -1 for the end of stream, -2 for no data at moment
   */
  public int r() {
    try {
      if (_ub != null && _ub.size() > 0)
        return (int) _ub.pop() & 0xFF;
      int status = _tryRead();
      return _bb.hasRemaining() ? (int) _bb.get() & 0xFF : status == - 1 ? -1 : -2;
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public Long readBuf(Buf buf, long n) {
    try {
      int read = 0;      
      if (_ub != null && _ub.size() > 0)
        read += _ub.pipeTo(buf, (int)n);
      while(true) {
        int status = _tryRead();
        
        int toCopy = (int)n - read;
        read += buf.pipeFrom(_bb, Math.min(toCopy, _bb.remaining()));
        
        if (this._blocking || status <= 0 || (int)n - read <= 0) // never loop in blocking mode
          return read > 0 ? Long.valueOf(read) : status == -1 ? null : Long.valueOf(0);
      }
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public InStream unread(long n) { return unread((int)n); }
  public InStream unread(int n) {
    try {
      // don't take the hit until we know we need to wrap
      // the raw input stream with a CircularByteBuffer
      if (_ub == null)
        _ub = new CircularByteBuffer(128);
      _ub.push((byte)n);
      return this;
    } catch (BufferUnderflowException e) { throw IOErr.make(e).val; }
      catch (BufferOverflowException e) { throw IOErr.make(e).val; }
  }

  public long skip(long n) {
    try {
      int skipped = 0;
      // if (_ub != null && _ub.size() > 0)
      //   read += _ub.pipeTo(buf, (int)n); // FIXME Skipping must skip unread bytes first. 
      while(true) {
        int status = _tryRead();
        int toSkip = Math.min((int)n-skipped, _bb.remaining());

        _bb.position(_bb.position() + toSkip);
        skipped += toSkip;
        
        if (this._blocking || status <= 0 || (int)n-skipped <= 0)  // never loop in blocking mode
          return skipped > 0 ? Long.valueOf(skipped) : Long.valueOf(status);
      }
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public boolean close() {
    try {
      _ch.close();
      return true;
    } catch (IOException e) { return false; }
  }
  
  /**
   * @return -1 if closed, 0 if current chunk ended, 1 otherwise
   */
  public int _tryRead() throws IOException {
    if (!_bb.hasRemaining() && _ch.isOpen()) {
      _bb.clear();
      int read = -2;
      while(_bb.hasRemaining() && (read = _ch.read(_bb)) > 0) {
        if (this._blocking) break; // never loop in blocking mode
      }
      if (read == -1)
        close();
      _bb.flip();
      return read <= 0 ? read : 1;
    }
    return _ch.isOpen() ? 1 : -1;
  }
}