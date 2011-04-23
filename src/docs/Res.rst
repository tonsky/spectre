.. image:: _images/response.jpg
   :class: article_cover cover_response

=====
 Res
=====

:class:`Res` is your way to tell Spectre what it should send to the client in response to his request. :class:`Res` may be returned by view or by any middleware. Moreover, middlewares are allowed to change returned :class:`Res` as they need, or return their own instead.

Typical usage is to pass the content of the page to constructor as a :class:`Str`::
  
  Res("<h1>Hello world!</h1>")

You can also pass :class:`InStream`, :class:`File` or :class:`List` (merged content of list elements, converted to strings, will be sent), or any other :class:`Obj` that supports :func:`~Obj.toStr`.

Also see :doc:`templates`.

.. class:: Res

   .. function:: new make(Obj? content, Str:Obj options := [:])
   
      Supported options:
      
      + ``"statusCode"``: ``Int``. Http status code of this response;
      + ``"contentType"``: ``Str``. Content type string.

   .. attribute:: headers
   
      :class:`QueryMap` of http headers that should be sent to client in http response. Allows multiple values for single key (use :func:`~QueryMap.add` or :func:`~QueryMap.setList` to add, :func:`~QueryMap.set` to override).
   
   .. attribute:: statusCode
      
      ``Int``. Status code of http response. Defaults to 200 (OK). See `List of status codes <http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10>`_.
      
   .. attribute:: content
    
      Body of http response that will be sent to server. Supported types:
      
      :class:`Str`
        Will be sent as-is.
        
      :class:`InStream`
        Content of this stream will be sent until the end of the stream.
        
      :class:`File`
        File will be read and its content will be sent to client.
        
      :class:`List`
        Elements of this list will be merged together and sent to client.
        
      :class:`Obj`
        ``content.toStr`` will be sent.
   
   .. function:: setCookie(spectre::Cookie cookie)
      
      A command to set a cookie will be sent to the client in this response. Note that setting cookie in :class:`Res` will not automatically make it visible in *current* :class:`Req`.
  
      See :class:`Cookie`.
  
   .. function:: deleteCookie(Str cookieName)
  
      A command for the client to remove cookie will be sent in this response.
      
Res subclasses
--------------

There are a number of special :class:`Res` subclasses addressing most common response needs.

.. class:: ResRedirect

   .. function:: make(Uri redirectTo)
   
      Issue a 302 redirect (found).

      
.. class:: ResPermanentRedirect

   .. function:: make(Uri redirectTo)

      Issue a 301 redirect (moved permanently).


.. class:: ResNotModified

   Issue a 304 Not Modified response. Use this if page was not modified since last client’s request and can be loaded from browser’s cache.


.. class:: ResNotFound

   Issue a 404 Not Found response. Use this if requested page doesn’t exist on your server.


.. class:: ResForbidden

   Issue a 403 Forbidden response. Client is not authorized to see requested page/run requested operaion.


.. class:: ResServerError

   Issue a 500 Internal Server Error response. The server encountered an unexpected condition which prevented it from fulfilling the request.


.. class:: ResBadRequest

   Issue a 400 Bad Request response. The request could not be understood by the server due to malformed syntax.


.. class:: ResMethodNotAllowed

   .. function:: make(Str[] permittedMethods)

      Issues a 405 Method Not Allowed response. The method specified in the request is not allowed for the resource identified by the uri. ``permittedMethods`` should contains a list of methods allowed for this resource (e.g. ``["get", "post"]``).
   
   
.. class:: ResGone

   Issue a 410 Gone response. The requested resource is no longer available at the server and no forwarding address is known.
   