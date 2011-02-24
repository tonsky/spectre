**
** A message support middleware.
** 
class MessageMiddleware : Middleware {
  MessageStoreImpl storeImpl

  ** Name of the attribute to store `MessageStore` in `Req#context`.
  Str contextAttr := "messageStore"

  new make(MessageStoreImpl storeImpl, |This|? f := null) { this.storeImpl = storeImpl; f?.call(this) }
  
  override Req before(Req req) {
    store := MessageStore { impl = storeImpl; it.req = req }
    return req.dup([contextAttr: store])
  }

  override Res? safeAfter(Req req, Res res) {
    MessageStore store := req.context(contextAttr)
    store.onStore(res)
    return res
  }
}

**
** A message object to be stored and displayed.
** 
const class Message {
  ** Arbitrary set of tags (priority, severity, etc)
  const Str[] tags
  
  ** Message text (Str or SafeSrt)
  const Obj text
  
  new make(Obj text, Str[] tags := ["info"]) { this.text = text; this.tags = tags }
}

**
** Interface to work with messages from view.
**  
class MessageStore {
  MessageStoreImpl impl
  Req req
  Message[] messages := [,]
  Bool read := false
      
  Message[] get() { read = true; return impl.get(req) }
  Void store(Message message) { messages.add(message) }
  
  new make(|This| f) { f.call(this) }
  internal Void onStore(Res res) { if(read) impl.clear(req, res); impl.store(messages, req, res) }
}

**
** Base class for custom message stores
** 
mixin MessageStoreImpl {
  abstract Message[] get(Req req)
  abstract Void clear(Req req, Res res)
  abstract Void store(Message[] messages, Req req, Res res)  
}



