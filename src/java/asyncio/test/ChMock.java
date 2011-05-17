package fan.spectre;

import fan.sys.*;

import java.nio.*;
import java.nio.channels.*;

/**
 * Mock socket that emulates chunked data arrival.
 */
class ChMock implements ReadableByteChannel {
  public boolean _open = true;
  public byte[][] _chunks;
  public boolean _blocking;
  public int _chunksIdx = 0, _strPos = 0;
  
  public ChMock(Object[] chunks, boolean blocking) { 
    try {
      this._chunks = new byte[chunks.length][];
      for(int i=0;i<chunks.length;++i) {
        if (chunks[i] instanceof String)      
          _chunks[i] = ((String)chunks[i]).getBytes("UTF-8");
        else if (chunks[i] instanceof byte[])
          _chunks[i] = (byte[])chunks[i];
        else
          throw Err.make("ChMock accepts only ASCII String or byte[], not " + chunks[i].getClass()).val;
      }
      this._blocking = blocking;
    } catch (java.io.UnsupportedEncodingException e) {
      throw Err.make("What, no UTF-8?", e).val;
    }
  }
  
  public int read(ByteBuffer dst) {
    if (_chunksIdx >= _chunks.length) return -1; // no more data
    while (_strPos >= _chunks[_chunksIdx].length) { // no more data in current chunk
      _chunksIdx++;
      _strPos = 0;
      if (_chunksIdx >= _chunks.length) return -1;
      if (!_blocking) return 0;
    }
    
    // otherwise send what rest of the current chunk
    int toCopy = Math.min(dst.remaining(), _chunks[_chunksIdx].length - _strPos);
    dst.put(_chunks[_chunksIdx], _strPos, toCopy);
    _strPos += toCopy;
    return toCopy;
  }
  
  public boolean isOpen() {
    return _open;
  }
  
  public void close() {
    _open = false;
  }
}