==========
 Sessions
==========

:class:`Session` provides a name/value map associated with a specific browser "connection" to the web server. You can inject session to your view using ``Session session`` view arg (recommended) or get it from ``req`` via ``req.context("session")``.

.. note::
   Sessions will only be avaliable after :class:`SessionMiddleware` was executed (see below).

.. class:: Session

   A common interface you’ll work with in your code.

   .. function:: Obj? get(Str k)
   
      Return value stored in current session.
      
   .. function:: This set(Str k, Obj? v)
   
      Store value in current session.

   .. attribute:: map
   
      ``[Str:Obj?]`` of values stored in the current session. Note that this field will usually be read-only, use :func:`set` method to set/change value in current session.
   
Setting up
----------

To set up sessions, create a :class:`SessionMiddleware` instance, specify its :attr:`~SessionMiddleware.sessionStore` attribute and add it to the :attr:`Setting.middlewares` list. For now, spectre offers only one type of store: :class:`InmemorySessionStore`.

Example::

  sessionMiddlware := SessionMiddleware {
    sessionStore = InmemorySessionStore { 
      maxSessionAge = 14day
      cleanupPeriod = 1hr
    }
  }
  
  middlewares = [sessionMiddlware]


.. class:: SessionMiddleware

   .. attribute:: sessionStore
   
      :class:`SessionStore`. How to store sessions. Must be assigned in constructor.

   .. attribute:: cookieName
   
      :class:`Str`. Name of cookie used to identify user’s session. Defaults to ``"__spectre_session"``.
      
   .. attribute:: cookieDomain
   
      :class:`Str?`. Domain parameter of session cookie. See :attr:`Cookie.domain`. Defaults to ``null``.
      
   .. attribute:: cookiePath
   
      :class:`Str?`. Path parameter of session cookie. See :attr:`Cookie.path`. Defaults to ``null``.
      
   .. attribute:: cookieSecure
   
      :class:`Str?`. Secure parameter of session cookie. See :attr:`Cookie.secure`. Defaults to ``false``.

   .. attribute:: contextAttrName
   
      :class:`Str`. Name to store session in :attr:`Req.context`. Defaults to ``"session"``.

   .. attribute:: saveEveryRequest
   
      :class:`Bool`. If set to ``true``, session’s last accessed time and session cookie will be updated on each request.


.. class:: InmemorySessionStore

   Store all session data in memory. For performance reasons it’s allowed to store constant objects only (``toImmutable == true``).
   
   .. attribute:: maxSessionAge
   
      :class:`Duration?`. All sessions updated more than :attr:`maxSessionAge` ago will be invalidated. When set to null, sessions will last until browser window close. Defaults to 14 days.

   .. attribute:: cleanupPeriod
   
      :class:`Duration?`. Session store will run cleaning (removing expired sessions from memory) with this interval. When set to null, no cleaning will be run. Defaults to 1 hour.