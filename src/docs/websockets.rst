===================
 WebSocket support
===================

Spectre currently supports `version 13 <http://tools.ietf.org/html/rfc6455>`_ of WebSocket Protocol specification, the same that’s implemented in latest browsers for now. WebSocket client API documentation can be found `here <http://dev.w3.org/html5/websockets/>`_.

To process WebSocket connections in Spectre, your app instance must override :func:`~Settings.wsProcessor` factory method::

  override WsProcessor? wsProcessor(WsHandshakeReq req) {
    if (req.uri.pathStr == "/") return FooWsProcessor(pool)
    else throw Err("Unknown path ${req.uri.pathStr}")
  }

:func:`~Settings.wsProcessor` should return :class:`WsProcessor` instance that will process this WebSocket connection. Here you do all your routing work etc. You can always return a static instance that implements :class:`WsProcessor` directly, but usually it’ll be actors, one per connection, extending :class:`WsActor` helper class:

.. class:: WsActor

   WebSocket processor that processes data in a separate thread.

   .. function:: asyncOnReady(WsConn conn)

      Will be called after connection has been successfully negotiated.
      
   .. function:: asyncOnMsg(WsConn conn, Obj msg)

      When message has been received from client. Obj could be Str or Buf for text and binary fragments, respectively.

   .. function:: asyncOnClose(WsConn conn)

      When client has closed connection. It’s invalid to read/send messages from/to ``conn`` in this method.

When you need to interoperate with WebSocket, use ``conn`` argument:

.. class:: WsConn

   .. attribute:: req

      ``WsHandshake``. Handshake request that connection has started from.

   .. function:: read()

      ``Str``, ``Buf`` or ``null``. Read next message from socket. This operation blocks until there’ll be a message in WebSocket. Returns ``null`` if connection was closed before anything was received.

   .. function:: writeStr(Str msg)

      Write text message to the WebSocket.

   .. function:: writeBinary(Buf msg)

      Write binary message to the WebSocket.

   .. function:: close()

     Finish WebSocket communication. After this method called it’s impossible to write or read to/from this connection anymore.
     

.. note::

   You cannot use :func:`WsConn.read` from :class:`WsActor`’s ``async_*`` methods because reading is already pending in the web server thread.
   
Synchronous WebSocket processing can be done by extending :class:`WsProcessor` itself:
   
   .. class:: WsProcessor

      WebSocket processor that processes data in a synchronous manner.

      .. function:: onHandshake(WsHandshakeReq req)

         Should return WebSocket handshake response. May be overriden to choose protocol or tune smth else in handshake response.

      .. function:: onReady(WsConn conn)

         Will be called after connection has been successfully negotiated.

      .. function:: onMsg(WsConn conn, Obj msg)

         When message has been received from client.

      .. function:: onClose(WsConn conn)

         When client has closed connection. It’s invalid to read/send messages from/to ``conn`` in this method.
         
Finally, an example of :class:`WsActor` implementation demonstrates both sync and async processing::

  const class FooWsProcessor : WsActor {
    new make(ActorPool pool) : super(pool) {}
  
    // synchronous processing (we’re overriding WsProcessor here)
    override Void onReady(WsConn conn) {
      conn.writeStr("Waiting for your message")
      
      // Processing of this socket will block until read returns:      
      Obj? data := conn.read()
      if (data == null) { return }
      
      // First message to be processed here, 
      // all the rest to be received asynchronously:      
      conn.writeStr("Received ‘${data}’ (synchronously)")

      // Sheduling some work for later:    
      sendLater(0.5sec) |->|{ conn.writeStr("Send after 0.5sec") }
      sendLater(1sec)   |->|{ conn.writeStr("Send after 1sec") }
      sendLater(3sec)   |->|{ conn.writeStr("Close after 3sec..."); conn.close }
    }

    // asynchronous processing example
    override Void asyncOnMsg(WsConn conn, Obj msg) {
      conn.writeStr("Received ‘" + msg + "’ (asynchronously)")
    }
  }
