using inet::IpAddr
using inet::SocketOptions

**
** TCP socket. Can be listened in `SelActor` for read events.
** Data from this socket can be read in blocking mode only, but
** when first message is fully read, you can schedule this socket
** back to 'SelActor' to wait for the next message.
**
class TcpSocket {
  ** Callback to be called when this socket has something to read.
  |SelActor, TcpSocket->Void|? readReady
  
  ** Make a new unbound, unconnected TCP socket.
  new make() {}

  // ** Is this socket bound to a local address and port.
  // native Bool isBound()

  ** Is this socket connected to the remote host.
  native Bool isConnected()

  native Bool isClosed()

  // ** Get the bound local address or null if unbound.
  // native IpAddr? localAddr()
  // 
  // ** Get the bound local port or null if unbound.
  // native Int? localPort()

  ** Get the remote address or null if not connected.
  native IpAddr? remoteAddr()

  ** Get the remote port or null if not connected.
  native Int? remotePort()

  // ** Bind this socket to the specified local address.  If addr is null
  // ** then the default IpAddr for the local host is selected.  If port
  // ** is null an ephemeral port is selected.  Throw IOErr if the port is
  // ** already bound or the bind fails.  Return this.
  // native This bind(IpAddr? addr, Int? port)

  // ** Connect this socket to the specified address and port.  This method
  // ** will block until the connection is made.  Throw IOErr if there is a
  // ** connection error.  If a non-null timeout is specified, then block no
  // ** longer then the specified timeout before raising an IOErr.
  // native This connect(IpAddr addr, Int port, Duration? timeout := null)

  ** Get the input stream used to read data from the socket.  The input
  ** stream is automatically buffered according to SocketOptions.inBufferSize.
  ** If not connected then throw IOErr.
  native InStream in()
  
  ** Get the output stream used to write data to the socket.  The output
  ** stream is automatically buffered according to SocketOptions.outBufferSize
  ** If not connected then throw IOErr.
  native OutStream out()

  ** Close this socket and its associated IO streams.  This method is
  ** guaranteed to never throw an IOErr.  Return true if the socket was
  ** closed successfully or false if the socket was closed abnormally.
  native Bool close()

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  **
  ** Access the SocketOptions used to tune this socket.  The
  ** following options apply to TcpSockets:
  **   - inBufferSize
  **   - outBufferSize
  **   - keepAlive
  **   - receiveBufferSize
  **   - sendBufferSize
  **   - reuseAddr
  **   - linger
  **   - receiveTimeout
  **   - noDelay
  **   - trafficClass
  **  Accessing other option fields will throw UnsupportedErr.
  **
  virtual SocketOptions options() {
    SocketOptions#.method("make").call(this)
  }

  internal native Int? getInBufferSize()
  internal native Void setInBufferSize(Int? v)

  internal native Int? getOutBufferSize()
  internal native Void setOutBufferSize(Int? v)

  internal native Bool getKeepAlive()
  internal native Void setKeepAlive(Bool v)

  internal native Int getReceiveBufferSize()
  internal native Void setReceiveBufferSize(Int v)

  internal native Int getSendBufferSize()
  internal native Void setSendBufferSize(Int v)

  internal native Bool getReuseAddr()
  internal native Void setReuseAddr(Bool v)

  internal native Duration? getLinger()
  internal native Void setLinger(Duration? v)

  internal native Duration? getReceiveTimeout()
  internal native Void setReceiveTimeout(Duration? v)

  internal native Bool getNoDelay()
  internal native Void setNoDelay(Bool v)

  internal native Int getTrafficClass()
  internal native Void setTrafficClass(Int v)
}