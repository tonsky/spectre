
using concurrent

**
** Web socket processor that can process data in separate thread.
** There’re two basic ways to work with web socket:
**   1. in a separate thread (asynchronously); or 
**   2. without creating a thread (synchronously).
** 
** Asynchonously, all messages are delivered to the actor’s thread
** to 'asyncOn_*' set of methods. You cannot use 'conn.read' because reading
** is already pending in the web server thread.
** 
** To process messages synchronously, one shall override 'on_*' set of methods
** from `WsProcessor` mixin. It’s possible to read from 'conn' in this methods,
** but the execution will block until there’ll be message in web socket.
**
** To interoperate with web socket itself (read/write/close), use `WsConn` `conn` arg.
** To modify handshake response, override `WsProcessor.onHandshake`. 
** It’s also impossible to read or write from/to socket in `#asyncOnClose` or `#onClose`
** because socket is already closed when they are called.
** 
const class WsActor : DynActor, WsProcessor {
  private static const Log log := Log.get("spectre")
  
  new make(ActorPool pool) : super(pool) {}
  
  // Asynchronous processing part
  ** Will be called after connection has been successfully negotiated.
  protected virtual Void asyncOnReady(WsConn conn) {}
  
  ** When message has been received from client.
  protected virtual Void asyncOnMsg  (WsConn conn, Buf msg) {}
  
  ** When client has closed connection. It’s invalid to read/send messages from/to 'conn' in this method.
  protected virtual Void asyncOnClose(WsConn conn) {}
  
  protected Void _asyncOnReady(WsConn conn)          { try asyncOnReady(conn); catch (Err e) log.err("Error in web socket processor", e) }
  protected Void _asyncOnMsg  (WsConn conn, Buf msg) { try asyncOnMsg  (conn, msg); catch (Err e) log.err("Error in web socket processor", e) }  
  protected Void _asyncOnClose(WsConn conn)          { try asyncOnClose(conn); catch (Err e) log.err("Error in web socket processor", e) }

  // WsProcessor impl part (synchronous processing).
  // Falls back to async processing by default.
  
  ** Will be called after connection has been successfully negotiated.
  override Void onReady(WsConn conn)          { this->sendAsyncOnReady(conn) }
  
  ** When message has been received from client.
  override Void onMsg  (WsConn conn, Buf msg) { this->sendAsyncOnMsg(conn, Unsafe(msg)) }
  
  ** When client has closed connection. It’s invalid to read/send messages from/to 'conn' in this method.
  override Void onClose(WsConn conn)          { this->sendAsyncOnClose(conn) }
}