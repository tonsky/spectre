=================
 Defining an app
=================

To define an app, you:

  1. Create a proper Fantom pod with ``build.fan`` file in it. This file will be used by Spectre to build your app.
  2. In this pod you create a class extending :class:`Settings`. There should be only one such class. This class will be an entry point to your application.
  3. In the constructor of your :class:`Settings` class you define:
  
     * routes (by assigning :class:`Router` to the :attr:`Settings.routes`),
     * middlewares (by assigning list of :class:`Middleware`-s to the :attr:`Settings.middlewares`), if any,
     * template renderer (by assigning :class:`MustacheRenderer` to the :attr:`Settings.renderer`).
     
  4. If you are going to serve WebSockets, see `websockets` for how to define WebSockets handler.


.. class:: Settings

   .. attribute:: appDir

      ``File``. Will be set in ``make`` from ``params``. Use this to set up templates dir relative to appDir, for example.
      
   .. attribute:: debug
   
      Whether your app is in debug mode or not.

   .. function:: wsProcessor(WsHandshakeReq req)
   
      This method should return :class:`WsProcessor` instance that will process this WebSocket connection. See :class:`WsActor`.
      
   .. function:: root()
   
      Override this to construct :class:`Turtle`-s hierarchy all by yourself.
