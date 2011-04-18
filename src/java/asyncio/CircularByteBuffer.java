package fan.spectre;

import fan.sys.*;
import java.nio.*;

public class CircularByteBuffer {
  public byte[] _buf;
  public int _b = 0, _e = 0;
  
  public CircularByteBuffer(int size) { this._buf = new byte[size]; }
  public void push(byte b) {
    if (size() < _buf.length-1) {
      _buf[_e] = b;
      _e = (_e + 1) % _buf.length;
    } else throw new BufferOverflowException();
  }
  
  public byte pop() {
    if (size() > 0) {
      byte res = _buf[_b];
      _b = (_b + 1) % _buf.length;
      return res;
    } else throw new BufferUnderflowException();
  }

  public int pipeTo(Buf buf, int n) {
    int toCopy = Math.min(n, size());
    if (_b <= _e || _b + toCopy<_buf.length) {
      buf.pipeFrom(_buf, _b, toCopy);
      _b += toCopy;
    } else {
      int toCopy1 = _buf.length - _b;
      buf.pipeFrom(_buf, _b, toCopy1);
      int toCopy2 = toCopy - toCopy1;
      buf.pipeFrom(_buf, 0, toCopy2);
      _b = toCopy2;
    }
    return toCopy;
  }
  
  public int size() {
    return _e >= _b ? _e-_b : _e+_buf.length-_b;
  }
}
