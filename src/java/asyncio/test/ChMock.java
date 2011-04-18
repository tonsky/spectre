package fan.spectre;

import fan.sys.*;

import java.nio.*;
import java.nio.channels.*;

/**
 * Mock socket that emulates chunked data arrival.
 */
class ChMock implements ReadableByteChannel {
  public boolean _open = true;
  public String[] _chunks;
  public boolean _blocking;
  public int _chunksIdx = 0, _strPos = 0;
  
  public ChMock(String[] chunks, boolean blocking) { this._chunks = chunks; this._blocking = blocking; }
  
  public int read(ByteBuffer dst) {
    if (_chunksIdx >= _chunks.length) return -1; // no more data
    while (_strPos >= _chunks[_chunksIdx].length()) { // no more data in current chunk
      _chunksIdx++;
      _strPos = 0;
      if (_chunksIdx >= _chunks.length) return -1;
      if (!_blocking) return 0;
    }
    
    // otherwise send what rest of the current chunk
    int toCopy = Math.min(dst.remaining(), _chunks[_chunksIdx].length() - _strPos);
    dst.put(_chunks[_chunksIdx].getBytes(), _strPos, toCopy);
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