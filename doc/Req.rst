.. image:: _images/request.png
   :class: article_cover cover_request

=====
 Req
=====

Represents incoming http request. A new instance of :class:`Req` will be created for each incoming request. :class:`Req` instances are read-only, but :class:`Middleware` can create a copy with another :attr:`~Req.context` using :func:`~Req.dupWith` method.

.. class:: Req

   .. attribute:: pathInfo
   
      ``Uri`` of current http request.

   .. attribute:: get
   .. attribute:: post

      :class:`QueryMap` of current request’s arguments (GET and POST respectively). :class:`QueryMap` interface is mostly equivalent to ``[Str:Str]``, except that it allows multiple values for single key (accessed using ``getList(Str key)`` method).

   .. attribute:: request

      Values from both :attr:`get` and :attr:`post` combined in a single :class:`QueryMap`. If value exists in both :attr:`get` and :attr:`post`, value from :attr:`post` is used.

   .. attribute:: headers

      ``[Str:Str]`` of HTTP request headers.

   .. attribute:: method
   
      ``Str`` of HTTP request method (``"get"`` or ``"post"`` or another).

   .. attribute:: cookies

      ``[Str:Str]`` of current browser session’s cookies. They’re for reading only, to set cookie, use :func:`Res.setCookie`.

   .. attribute:: context
   
      ``[Str:Obj?]`` usually populated by middlewares to prepare values for views. All values presented in ``context`` can be used as view arguments (resolved by name).
 
      Two standard use cases of :attr:`context` are:

      + :class:`Router` puts url path capture values to context if url matches this route;
      + :class:`SessionMiddleware` puts ``Session session`` object in context.
      
      This slot and its value are both readonly. See :func:`~Req.dupWith`.

   .. function:: dupWith(Str:Obj? overrde)
   
      Returns a copy of current :class:`Req` with values in context set (added or overriden) with ``overrde`` parameter values.
      
   .. attribute:: in
   
      :class:`InStream`. Raw HTTP request input stream.