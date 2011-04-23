=========
 Spectre
=========

Spectre is the general-purpose web application framework for `Fantom <http://fantom.org>`_ language.

Main features
-------------

* higly customizable;
* batteries included: flexible url router, cookies, messages, custom sessions;
* full-featured forms library;
* Mustache templates for presentation layer;
* development server with:

  * non-blocking IO cycle for perfect scalability;
  * WebSocket protocol draft 76 support;
  * instant app reload in dev mode.


Documentation
-------------

Spectre documentation can be found at `spectreframework.org/documents/ <http://spectreframework.org/documents/>`_ or in a ``doc`` folder of Spectre distribution.


Sample application
------------------
::

	using spectre

  class HelloWorldApp : Settings {
    new make(Str:Obj? params) : super(params) {
      routes = Router {
        ["/*", |->Res| { Res("Hello, world!") }]
      }
    }
  }

For more examples take a look at ``examples`` folder of Spectre distribution.

Building Spectre from sources
-----------------------------

You’ll need:

* `Fantom 1.0.58 <http://fantom.org>`_;
* `Printf <https://bitbucket.org/ivan_inozemtsev/printf>`_;
* `Mustache <https://bitbucket.org/xored/mustache>`_;
* And `Spectre <https://bitbucket.org/xored/spectre>`_ of course.

Set up Fantom’s ``jdkHome`` property in ``$FAN_HOME/etc/build/config.props``. Then run::

  >>> fan printf/build.fan
  >>> fan mustache/build.fan
  >>> fan spectre/src/build.fan
  >>> cp $FAN_HOME/lib/fan/printf.pod spectre/lib/fan/
  >>> cp $FAN_HOME/lib/fan/mustache.pod spectre/lib/fan/
  >>> cp $FAN_HOME/lib/fan/spectre.pod spectre/lib/fan/

Now add ``spectre/bin`` to your ``$PATH`` and that’s it.