============================
 Spectre development server
============================

Spectre comes with built-in development server based on Fantom's `wisp web server <http://fantom.org/doc/wisp/index.html>`_. Its main purpose is to monitor source files in you app's folder and reload them when something has been changed, so you'll see a new version in your browser with no need to restart server manually.

Running devserver
-----------------

To run development server, you'll need both Fantom 1.0.56 and Spectre installed (see :doc:`installation`). Execute the following in your command prompt::

  >>> fan spectre::WispServer <path_to_your_app_folder>
  [20:09:47 23-Nov-10] [info] [spectre] Watching <path_to_your_app_folder>/ for modifications
  [20:09:47 23-Nov-10] [info] [web] WispService started on port 8080
  
To bind on specific port use::

  >>> fan spectre::WispServer -port 8000 <path_to_your_app_folder>
  
Serving static files
--------------------

When developing app, you'll probably want to serve static files from the same devserver as the rest of the app. Spectre includes :class:`StaticView` turtle for that purpose. Just include it into your app's routing scheme::

  router := Router {
    ...
    
    ["/css/*", StaticView(appDir + `static/styles/`)],
    ["/js/*", StaticView(appDir + `static/scripts/`)]
  }
  
