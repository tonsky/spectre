package fan.spectre;

import fan.sys.*;
import fan.inet.*;
import java.io.*;
import java.net.*;
import java.nio.*;
import java.nio.channels.*;
import java.nio.channels.spi.*;

public class TcpListenerPeer {
  public ServerSocketChannel _ch;
  
  public static TcpListenerPeer make(TcpListener fan) {
    try { return new TcpListenerPeer(); }
    catch (IOException e) { throw IOErr.make(e); }
  }

  protected TcpListenerPeer() throws IOException {
    _ch = ServerSocketChannel.open();
  }

  public boolean isBound(TcpListener fan) { return _ch.socket().isBound(); }

  public boolean isClosed(TcpListener fan) { return !_ch.isOpen(); }

  public IpAddr localAddr(TcpListener fan) {
    if (!_ch.socket().isBound()) return null;
    InetAddress addr = _ch.socket().getInetAddress();
    if (addr == null) return null;
    return IpAddrPeer.make(addr);
  }

  public Long localPort(TcpListener fan) {
    if (!_ch.socket().isBound()) return null;
    int port = _ch.socket().getLocalPort();
    if (port <= 0) return null;
    return Long.valueOf(port);
  }

  public TcpListener bind(TcpListener fan, IpAddr addr, Long port, long backlog) {
    try {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : port.intValue();
      _ch.configureBlocking(false);      
      _ch.socket().bind(new InetSocketAddress(javaAddr, javaPort), (int)backlog);
      return fan;
    } catch (IOException e) { throw IOErr.make(e); }
  }

  public TcpSocket doAccept(TcpListener fan) {
    try {
      SocketChannel __ch = _ch.accept();
      // __ch.configureBlocking(false);
      TcpSocket s = TcpSocket.make();
      s.peer.connected(s, __ch);
      return s;
    } catch (IOException e) { throw IOErr.make(e); }
  }

  public boolean close(TcpListener fan) {
    try {
      _ch.close();
      return true;
    } catch (Exception e) { return false; }
  }

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  public long getReceiveBufferSize(TcpListener fan) {
    try { return _ch.socket().getReceiveBufferSize(); }
    catch (IOException e) { throw IOErr.make(e); }
  }

  public void setReceiveBufferSize(TcpListener fan, long v) {
    try { _ch.socket().setReceiveBufferSize((int)v); }
    catch (IOException e) { throw IOErr.make(e); }
  }

  public boolean getReuseAddr(TcpListener fan) {
    try { return _ch.socket().getReuseAddress(); } 
    catch (IOException e) { throw IOErr.make(e); }
  }

  public void setReuseAddr(TcpListener fan, boolean v) {
    try { _ch.socket().setReuseAddress(v); }
    catch (IOException e) { throw IOErr.make(e); }
  }

  public Duration getReceiveTimeout(TcpListener fan) {
    try {
      int timeout = _ch.socket().getSoTimeout();
      if (timeout <= 0) return null;
      return Duration.makeMillis(timeout);
    } catch (IOException e) { throw IOErr.make(e); }
  }

  public void setReceiveTimeout(TcpListener fan, Duration v) {
    try {
      if (v == null)
        _ch.socket().setSoTimeout(0);
      else
        _ch.socket().setSoTimeout((int)(v.millis()));
    } catch (IOException e) { throw IOErr.make(e); }
  }
}