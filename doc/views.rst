.. image:: _images/views.png
   :class: article_cover cover_views

=======
 Views 
=======

There are three kinds of views supported:

+ class method;
+ static class method;
+ ``Func`` object (including closures; note that due to the `Fantom bug #1308 <http://fantom.org/sidewalk/topic/1308>`_ only :class:`Req` parameter is now supported for closures).

When called, view function args are resolved within :attr:`Req.context` by their names. :attr:`Req.context` contains all url path capture values, session object (usually under name ``"session"``; only if :class:`SessionMiddleware` was executed before). Additionaly, :class:`Req` itself is also allowed as a view argument, but it will be resolved by its type.

All non-default args of view function must be resovlable, otherwise :class:`ArgErr` will be thrown.

If view is a class method, new class instance will be creared upon each request. Constructor args are resolved exactly in the same way as view args are.

Returning result
----------------

Each view must return :class:`Res` instance or ``null``. 


Examples
--------

Having following route: ::

  "/orders/{id}/{action}/"

for request: ::

  /orders/76/edit/

:attr:`Req.context` will contain: ::

  ["id"     : "76", 
   "action" : "edit",
   "session": <session obj>]

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

  |Req req->Res?| { return Res(...) }



