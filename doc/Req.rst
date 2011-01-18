.. image:: _images/request.png
   :class: article_cover cover_request

=====
 Req
=====

Represents incoming http request. A new instance of :class:`Req` will be created for each incoming request. :class:`Req` instance is read-only except for :attr:`~Req.context`.

.. class:: Req

   .. attribute:: pathInfo
   
      ``Uri`` of current http request.

   .. attribute:: get
   .. attribute:: post

      :class:`QueryMap` of current request arguments (GET and POST respectively). :class:`QueryMap` interface is mostly equivalent to ``[Str:Str]``, except that it allows multiple values for single key (accessed using ``getList(Str key)`` method).

   .. attribute:: request

      Values from both :attr:`get` and :attr:`post` combined in a single :class:`QueryMap`. If value exists in both :attr:`get` and :attr:`post`, value from :attr:`post` is used.

   .. attribute:: headers

      ``[Str:Str]`` of http request headers.

   .. attribute:: method
   
      ``Str`` of http request method (``"get"`` or ``"post"`` or another).

   .. attribute:: cookies

      ``[Str:Str]`` of current browser session cookies. It’s for reading only, to set cookie, use :func:`Res.setCookie`.

   .. attribute:: context
   
      ``[Str:Obj?]`` usually populated by middlewares to prepare values for views. All values presented in ``context`` can be used as view arguments (resolved by name).
 
      Two standard use cases of :attr:`context` are:

      + :class:`Router` puts url path capture values to context if url matches this route;
      + :class:`SessionMiddleware` puts ``Session session`` object in context.
