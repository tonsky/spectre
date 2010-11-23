Turtles all the way down
========================

Turtles are unified building blocks of any spectre application. The name "Turtle" was inspired by Simon Willison's `article <http://simonwillison.net/2009/May/19/djng/>`_, one of the authors of Django, who originally proposed idea to unify different parts of Django under common contract. 

.. class:: Turtle

   .. function:: Res? dispatch(Req req)

      Process request. Turtles may process request by itself, skip processing to subsequent turtles or delegate processing to inherited turtles and do some pre/post processing job. Unified contract makes application parts rearrangeble, interchangable, easy to understand and reuse.

For now, following parts are implemented as turtles:

+ top-level error barriers (:class:`Handler500`, :class:`Handler404`);
+ middlewares (e.g. :class:`SessionMiddleware`);
+ :class:`Router`;
+ individual view wrappers;
+ :class:`TemplateRes` processors (template renderers);
+ flow control and grouping turtles (e.g. :class:`Selector`);
+ finally, whole application is just a :class:`Turtle`.


.. class:: Selector

   Groups a bunch of turtles and choose first of them that returns not-null :ref:`Res`: ::

       Selector {
         turtle1,
         turtle2,
         turtle3
       }


.. class:: Middleware

   Wraps another :ref:`Turtle` and do pre- or post-processing work on :ref:`Req`/:ref:`Res` objects.

   .. function:: This wrap(Turtle child)

      Wrap another turtle. Same may be done by assigning :attr:`child` in costructor.

   .. function:: Void before(Req req)

      Is called before invoking child's dispatch.

   .. function:: Res? after(Req req, Res? res)

      Is called after child's dispatch.

   .. function:: Res? safeAfter(Req req, Res res)

      Is called when child's dispatch returned not-null :class:`Res`, otherwise null be returned from middleware without invoking :func:`safeAfter`.

.. note::

   Usually a single instance of turtle will be constructed for each actor processing requests in web server, so you cannot rely on any local variables or actor's locals inside turtle instances.
