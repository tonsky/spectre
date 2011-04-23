.. image:: _images/request.jpg
   :class: article_cover cover_request

=====
 Req
=====

Represents incoming http request. A new instance of :class:`Req` will be created for each incoming request. :class:`Req` instances are read-only, but :class:`Middleware` can create a copy with another :attr:`~Req.context` using :func:`~Req.dup` method.

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

   .. attribute:: context(Str name)
   
      Resolve injectible data stored in :attr:`~Req.context` or :attr:`~Req.app` internal slots or :class:`Req` instance itself, by name. This method is internally used for injecting method and constructor params on views. It may be useful in middleware or when for some reasons you cannot use constructor/parameter injection in view. 
 
      Standart resolvable options are:

      * ``"req"`` is resovled to current :class:`Req` instance, if not overriden;
      * :class:`Router` puts url path capture values to context if url matches this route;
      * ``"session"`` is resolved to :class:`Session` if :class:`SessionMiddleware` is active.
      * ``"debug"`` is resolved to :attr:`Settings.debug` value.

      See :func:`~Req.dup`.

   .. function:: dup(Str:Obj? overrde)
   
      Returns a copy of current :class:`Req` with values in context added or overriden. This method will usually be used by middleware to populate context with new values and made them visible to children by passing returned :class:`Req`. See :attr:`~Req.context`.
      
   .. attribute:: in
   
      :class:`InStream`. Raw HTTP request input stream.