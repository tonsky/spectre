.. _Views:

Views 
=====
There are three kinds of views supported:

+ class method;
+ static class method;
+ ``Func`` object (closures; note that due to the `Fantom bug #1308 <http://fantom.org/sidewalk/topic/1308>`_ only :ref:`Req` parameter is supported for closures).

When called, view function args are resolved within :attr:`Req.context` by their names. :attr:`Req.context` contains all route capture values, session object (usually under name ``"session"``; only if :class:`SessionMiddleware` was executed before). Additionaly, :class:`Req` itself is also allowed as a view argument, but it will be resolved by its type.

All non-default args must be resovlable, otherwise ``ArgErr`` will be thrown.

When view is a class method, new class instance will be creared upon each request. Constructor args are resolved exactly in the same way as view args are.

.. rubric:: Returning result

Each view must return :class:`Res` instance or ``null``. 


.. rubric:: Examples

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

or::

  |Req req->Res?| { return Res(...) }



