using spectre

class MessagesApp : Router {
  new make() : super() {
    add(["/messages/", MessageViews#index])
  }
}

class MessageViews {
  virtual Res index(Req req, MessageStore messageStore) {
    if (req.get.get("msg", null) != null) {
      messageStore.store(Message(req.get["msg"], req.get["tags"].split(' ')))
      return ResRedirect(`/messages/`)
    }
    return TemplateRes("basic/basic.html", 
      ["content": "messages.html", "messages": messageStore.get, "messages?": messageStore.get.size > 0])
  }
}