
using web
using concurrent

**
** Descendant of this class is an entry point of web application
** 
abstract const class Settings {
//  new make(File appDir) { this.appDir = appDir }
  
//////////////////////////////////////////////////////////////////////////
// Settings
//////////////////////////////////////////////////////////////////////////
  
/*  File? appDir*/
  const Turtle? root
  const Bool debug := true
  
//////////////////////////////////////////////////////////////////////////
// WebSockets
//////////////////////////////////////////////////////////////////////////
  
  ** This method should return `WsProcessor` instance that will process
  ** this WebSocket connection. See `WsActor`.
  virtual WsProcessor? wsProcessor(WsHandshakeReq req) { throw UnsupportedErr() }
  
}
