
using concurrent

const class WsActor : DynActor, WsProcessor, WsConn {

  // Client contract part
  
  new make(ActorPool pool) : super(pool) {}
  
  protected virtual Void _onReady() {}
  protected virtual Void _onData(Buf msg) {}  
  protected virtual Void _onClose() {}

  // WsConn adapter part
  
  const AtomicRef connRef := AtomicRef(null)
  WsConn conn() { connRef.val }
  
  override Void writeStr(Str msg) { conn.writeStr(msg) }  
  override Void close() { conn.close }
  override WsHandshakeReq req() { conn.req }
  override Buf? read() { conn.read }
 
  // WsProcessor impl part
  
  override Void onReady(WsConn conn) { this.connRef.val = conn; this->sendOnReady() }
  override Void onData(WsConn conn, Buf msg) { this->sendOnData(Unsafe(msg)) }
  override Void onClose(WsConn conn) { this->sendOnClose() }
}