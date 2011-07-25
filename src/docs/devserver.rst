.. image:: _images/devserver.jpg
   :class: article_cover cover_devserver

============================
 Spectre development server
============================

Spectre comes with built-in development server. Its main purpose is to monitor source files in you app’s folder and reload them when something has been changed, so you’ll see a new version in your browser with no need to restart server manually.

Running devserver
-----------------

To run development server, you’ll need Spectre installed (see :doc:`installation`). Execute the following in your command prompt::

  >>> spectre rundevserver <path_to_your_app_folder>
  [20:09:47 23-Nov-10] [info] [spectre] Watching <path_to_your_app_folder>/ for modifications
  [20:09:47 23-Nov-10] [info] [spectre] Rebuildind pod <your_app_name> as file:<...>
  [20:09:47 23-Nov-10] [info] [spectre] Starting pod <...>_reloaded_1
  [20:09:47 23-Nov-10] [info] [web] spectre::WebServer started on port 8080
  
To bind on specific port use::

  >>> spectre rundevserver <path_to_your_app_folder> -port 8000
 
There’s also an option to write log to a file::

   >>> spectre rundevserver <path_to_your_app_folder> -logto /var/log/spectre.log

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

  >>> spectre runserver <path_to_your_app_folder>

It will disable hot app reloading, enable usage of Mustache templates cache, so your app will perform faster. If you want to change something in your application depending of server mode, use :attr:`Settings.debug` attribute which will be set to ``false`` when in production mode.