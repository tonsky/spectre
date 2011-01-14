
using concurrent

const class WsActor : DynActor {
  const WsConn conn // FIXME we depends on server here
  new make(WsConn conn, ActorPool pool) : super(pool) { this.conn = conn }
  
  virtual Void _onData(Buf msg) {}
  
  virtual Void _writeStr(Str msg) { conn.writeStr(msg) }
  virtual Void _close() { conn.close }
}
