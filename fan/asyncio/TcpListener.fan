using inet::IpAddr
using inet::SocketOptions

**
** Server TCP socket. Can be listened in `SelActor` for accept events.
**
class TcpListener {
  ** Callback to be called when this socket is ready for accept.
  |SelActor, TcpListener->Void| acceptReady
  
  new make(|SelActor, TcpListener->Void| acceptReady) { this.acceptReady = acceptReady }

  ** Is this socket bound to a local address and port.
  native Bool isBound()

  native Bool isClosed()

  ** Get the bound local address or null if unbound.
  native IpAddr? localAddr()

  ** Get the bound local port or null if unbound.
  native Int? localPort()

  ** Bind this listener to the specified local address.  If addr is null
  ** then the default IpAddr for the local host is selected.  If port
  ** is null an ephemeral port is selected.  Throw IOErr if the port is
  ** already bound or the bind fails.  Return this.
  native This bind(IpAddr? addr, Int? port, Int backlog := 50)

  ** Accept the next incoming connection.  This method blocks the
  ** calling thread until a new connection is established.  If this
  ** listener's receiveTimeout option is configured, then accept
  ** will timeout with an IOErr.
  TcpSocket accept() { return doAccept }
  private native TcpSocket doAccept()

  ** Close this server socket.  This method is guaranteed to never
  ** throw an IOErr.  Return true if the socket was closed successfully
  ** or false if the socket was closed abnormally.
  native Bool close()

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  **
  ** Access the SocketOptions used to tune this server socket.
  ** The following options apply to TcpListeners:
  **   - receiveBufferSize
  **   - reuseAddr
  **   - receiveTimeout
  **  Accessing other option fields will throw UnsupportedErr.
  **
  virtual SocketOptions options() {
    SocketOptions#.method("make").call(this)
  }

  internal native Int getReceiveBufferSize()
  internal native Void setReceiveBufferSize(Int v)

  internal native Bool getReuseAddr()
  internal native Void setReuseAddr(Bool v)

  internal native Duration? getReceiveTimeout()
  internal native Void setReceiveTimeout(Duration? v)
}