.. image:: _images/views.png
   :class: article_cover cover_views

=======
 Views 
=======

There are three kinds of views supported:

+ class method;
+ static class method;
+ ``Func`` object (closures).

When called, view function’s args are populated from :attr:`Req.context`, resolved by their names. These includes:

* :class:`Req` itself under the name ``"req"``.
* all url path capture values;
* session object (usually under name ``"session"``; only if :class:`SessionMiddleware` was executed before);
* all Settings slots under their names;

All non-default args of view function must be resovlable, otherwise :class:`ArgErr` will be thrown.

If view is a class method, new class instance will be creared upon each request. Constructor args are resolved exactly in the same way as view args are.

Returning result
----------------

View must return :class:`Res` instance, or ``null``. Returning ``null``, Spectre will try to execute following routes.

Examples
--------

Having following route: ::

  "/orders/{id}/{action}/"

for request: ::

  /orders/76/edit/

there will be::

  req.context("id") == "76"
  req.context("action") == "edit"
  req.context("session") == <session obj>
  req.context("req") == req

and view funcion may be defined as: ::

  Res? view (Req req, Str id, Str action, Str smth := "abc") {
    ...
  }

or as::

  static Res? view (Str action, Session session) {
    ...
  }

or even as::

  Res? view() {
    ...
  }

or as a closure::

  |Req req, Str action->Res?| { return Res(...) }
