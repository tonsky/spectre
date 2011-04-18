package fan.spectre;

import fan.sys.*;
import fan.inet.*;
import java.io.*;
import java.net.*;
import java.nio.*;
import java.nio.channels.*;
import java.nio.channels.spi.*;

public class TcpSocketPeer {
  public SocketChannel _ch;

  public int _inBufSize = 4096;
  public int _outBufSize = 4096;
  public IpAddr _remoteAddr;
  public int _remotePort;
  public InStream _in;
  public OutStream _out;

  public static TcpSocketPeer make(TcpSocket fan) { return new TcpSocketPeer(); }
  public TcpSocketPeer() {}

  // public boolean isBound(TcpSocket fan) { return _ch != null && _ch.socket().isBound(); }
   
  public boolean isConnected(TcpSocket fan) { return _ch != null && _ch.isConnected(); }

  public boolean isClosed(TcpSocket fan) { return !_ch.isOpen(); }

  // public IpAddr localAddr(TcpSocket fan) {
  //   if (!isBound(fan)) return null;
  //   InetAddress addr = _ch.socket().getLocalAddress();
  //   if (addr == null) return null;
  //   return IpAddrPeer.make(addr);
  // }
  // 
  // public Long localPort(TcpSocket fan) {
  //   if (!isBound(fan)) return null;
  //   int port = _ch.socket().getLocalPort();
  //   if (port <= 0) return null;
  //   return Long.valueOf(port);
  // }

  public IpAddr remoteAddr(TcpSocket fan) {
    if (!isConnected(fan)) return null;
    return _remoteAddr;
  }

  public Long remotePort(TcpSocket fan) {
    if (!isConnected(fan)) return null;
    return Long.valueOf(_remotePort);
  }

  public TcpSocket bind(TcpSocket fan, IpAddr addr, Long port) {
    try {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : port.intValue();
      _ch.socket().bind(new InetSocketAddress(javaAddr, javaPort));
      return fan;
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  // public TcpSocket connect(TcpSocket fan, IpAddr addr, long port, Duration timeout) {
  //   try  {
  //     int javaTimeout = (timeout == null) ? 0 : (int) timeout.millis();
  //     _ch = SocketChannel.open(new InetSocketAddress(addr.peer.java, (int)port)/*, javaTimeout*/); //TODO use timeout
  //     connected(fan, _ch);
  //     return fan;
  //   } catch (IOException e) { throw IOErr.make(e).val; }
  // }

  void connected(TcpSocket fan, SocketChannel _ch) throws IOException {
    this._ch = _ch;
    InetSocketAddress sockAddr = (InetSocketAddress)_ch.socket().getRemoteSocketAddress();
    _remoteAddr = IpAddrPeer.make(sockAddr.getAddress());
    _remotePort = sockAddr.getPort();
    
    // turn off Nagle's algorithm since we should
    // always be doing buffering in the virtual machine
    try { _ch.socket().setTcpNoDelay(true); }
    catch (Exception e) {}
    
    _in  = new ChannelInStream (_ch, getInBufferSize(fan).intValue(), true);
    _out = new ChannelOutStream(_ch, getOutBufferSize(fan).intValue());
  }
  
  public InStream in(TcpSocket fan) {
    if (_in == null) throw IOErr.make("not connected").val;
    return _in;
  }
  
  public OutStream out(TcpSocket fan) {
    if (_out == null) throw IOErr.make("not connected").val;
    return _out;
  }

  public boolean close(TcpSocket fan) {
    try {
      _ch.close();
      _in  = null;
      _out = null;
      return true;
    } catch (Exception e) { return false; }
  }

//////////////////////////////////////////////////////////////////////////
// Streaming Options
//////////////////////////////////////////////////////////////////////////

  public Long getInBufferSize(TcpSocket fan) {
    return (_inBufSize <= 0) ? null : Long.valueOf(_inBufSize);
  }

  public void setInBufferSize(TcpSocket fan, Long v) {
    if (_in != null) throw Err.make("Must set inBufferSize before connection").val;
    _inBufSize = (v == null) ? 0 : v.intValue();
  }

  public Long getOutBufferSize(TcpSocket fan) {
    return (_outBufSize <= 0) ? null : Long.valueOf(_outBufSize);
  }

  public void setOutBufferSize(TcpSocket fan, Long v) {
    if (_in != null) throw Err.make("Must set outBufSize before connection").val;
    _outBufSize = (v == null) ? 0 : v.intValue();
  }

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  public boolean getKeepAlive(TcpSocket fan) {
    try { return _ch.socket().getKeepAlive(); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setKeepAlive(TcpSocket fan, boolean v) {
    try { _ch.socket().setKeepAlive(v); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public long getReceiveBufferSize(TcpSocket fan) {
    try { return _ch.socket().getReceiveBufferSize(); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setReceiveBufferSize(TcpSocket fan, long v) {
    try { _ch.socket().setReceiveBufferSize((int)v); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public long getSendBufferSize(TcpSocket fan) {
    try { return _ch.socket().getSendBufferSize(); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setSendBufferSize(TcpSocket fan, long v) {
    try { _ch.socket().setSendBufferSize((int)v); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public boolean getReuseAddr(TcpSocket fan) {
    try { return _ch.socket().getReuseAddress(); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setReuseAddr(TcpSocket fan, boolean v) {
    try { _ch.socket().setReuseAddress(v); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public Duration getLinger(TcpSocket fan) {
    try {
      int linger = _ch.socket().getSoLinger();
      if (linger < 0) return null;
      return Duration.makeSec(linger);
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setLinger(TcpSocket fan, Duration v) {
    try {
      if (v == null)
        _ch.socket().setSoLinger(false, 0);
      else
        _ch.socket().setSoLinger(true, (int)(v.sec()));
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public Duration getReceiveTimeout(TcpSocket fan) {
    try {
      int timeout = _ch.socket().getSoTimeout();
      if (timeout <= 0) return null;
      return Duration.makeMillis(timeout);
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setReceiveTimeout(TcpSocket fan, Duration v) {
    try {
      if (v == null)
        _ch.socket().setSoTimeout(0);
      else
        _ch.socket().setSoTimeout((int)(v.millis()));
    } catch (IOException e) { throw IOErr.make(e).val; }
  }

  public boolean getNoDelay(TcpSocket fan) {
    try { return _ch.socket().getTcpNoDelay(); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setNoDelay(TcpSocket fan, boolean v) {
    try { _ch.socket().setTcpNoDelay(v); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public long getTrafficClass(TcpSocket fan) {
    try { return _ch.socket().getTrafficClass(); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }

  public void setTrafficClass(TcpSocket fan, long v) {
    try { _ch.socket().setTrafficClass((int)v); }
    catch (IOException e) { throw IOErr.make(e).val; }
  }
}