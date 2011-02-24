==========
 Messages
==========

The messages framework allows you to temporarily store messages in one request and retrieve them for display in a subsequent request (usually the next one). Each message has text and list of tags which can be used for message classification (priority, severity etc).

.. class:: Message

   .. attribute:: text
   
      :class:`Str` or :class:`SafeStr`.

   .. attribute:: tags
   
      ``Str[]``. List of arbitrary tags.

   
Setting up
----------

To set up messages, you have to add :class:`MessageMiddleware` it to the :attr:`Setting.middlewares` list. Messages can be stored in session, cookie or in some custom store, but right from the box Spectre supports only :class:`SessionMessageStore`. To use it, you’ll need :class:`SessionMiddleware` in the middlewares list before :class:`MessageMiddleware`.

Example::

  middlewares = [
    SessionMiddleware { sessionStore = InmemorySessionStore() },
    MessageMiddleware(SessionMessageStore())
  ]

Using messages
--------------

With :class:`MessageMiddleware`, you’ll have ``MessageStore messageStore`` in the :attr:`Req.context` which you use to read or store messages. Once messages are read from the store, they are removed, so it’s possible to read them only once.

Example::
  
  Res view(MessageStore messageStore) {
    if (req.method == "POST") {
      // ... doing smth ...
      // storing msg:
      messageStore.store(Message("Changes saved"))
      // tags and safe str example:
      messageStore.store(Message(safe("<i>Something went wrong</i>"), ["error"]))
      return ResRedirect(req.pathInfo)
    }
    
    // reading messages:
    return TemplateRes("view.html", [
      "messages": messageStore.get,
      "messages?": messageStore.get.size > 0
    ])
  }


.. class:: MessageStore

   .. function:: get()
   
      :class:`Message` []. Read all stored messages and remove them from the store. After this request ends, these messages will not be avaliable for read anymore.

   .. function:: store(Message message)
   
      Stores message to be displayed in the subsequent requests.