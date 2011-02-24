**
** Built-in message store which store messages in session.
** This store requires `SessionMiddleware` before `MessageMiddleware`.
** 
class SessionMessageStore : MessageStoreImpl {
  Str sessionContextAttr := "session"
  Str msgSessionKey := "__spectre_messages"
  
  override Message[] get(Req req) {
    Session session := req.context(sessionContextAttr)
    Message[] messages := session.get(msgSessionKey)
    return messages
  }
  
  override Void clear(Req req, Res res) {
    Session session := req.context(sessionContextAttr)
    session.remove(msgSessionKey)
  }
  
  override Void store(Message[] messages, Req req, Res res) {
    Session session := req.context(sessionContextAttr)
    Message[] stored := session.get(msgSessionKey, [,])->rw
    stored.addAll(messages)
    session.set(msgSessionKey, stored)
  }
}