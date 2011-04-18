.. image:: _images/devserver.png
   :class: article_cover cover_devserver

============================
 Spectre development server
============================

Spectre comes with built-in development server. Its main purpose is to monitor source files in you app’s folder and reload them when something has been changed, so you’ll see a new version in your browser with no need to restart server manually.

Running devserver
-----------------

To run development server, you’ll need both Fantom 1.0.57 and Spectre installed (see :doc:`installation`). Execute the following in your command prompt::

  >>> fan spectre::RunDevServer <path_to_your_app_folder>
  [20:09:47 23-Nov-10] [info] [spectre] Watching <path_to_your_app_folder>/ for modifications
  [20:09:47 23-Nov-10] [info] [spectre] Rebuildind pod <your_app_name> as file:<...>
  [20:09:47 23-Nov-10] [info] [spectre] Starting pod <...>_reloaded_1
  [20:09:47 23-Nov-10] [info] [web] spectre::WebServer started on port 8080
  
To bind on specific port use::

  >>> fan spectre::RunDevServer -port 8000 <path_to_your_app_folder>
 
Serving static files
--------------------

When developing app, you’ll probably want to serve static files from the same devserver as the rest of the app. Spectre includes :class:`StaticView` turtle for that purpose. Just include it into your app’s routing scheme::

  router = Router {
    ...
    
    ["/css/*", StaticView(appDir + `static/styles/`)],
    ["/js/*", StaticView(appDir + `static/scripts/`)],
    ["/favicon.ico", StaticView(appDir + `static/img/favicon.ico`)]
  }

.. _devserver-production-mode:
  
Production mode
---------------

To run server in production mode, use ``RunServer`` class::

  >>> fan spectre::RunServer <path_to_your_app_folder>

It will disable hot app reloading, enable usage of mustache templates cache, so your app will perform faster. If you want to change something in your application depending of server mode, use :attr:`Settings.debug` attribute which will be set to ``false`` when in production mode.