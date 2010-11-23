Routing
=======

Routing scheme of spectre app is defined as one or more :class:`Router` :class:`turtles <Turtle>`.

.. class:: Router

   Take a list of ``[<route path>, <view function>]`` tuples. All routes are matched in the order they are defined until matched route is found. On the first match corresponding :doc:`view function <views>` will be invoked, and if it returns not-null value, this value is returned from :class:`Router` itself. If view returned null result, matching will be continued until the next matched route is found.

   .. rubric:: Example

   ::

       router := Router {
         ["/", ViewClass#index],
         ["/items/", ViewClass#itemsList],
         ["/item/{idx:\\d{4}}", ViewClass#itemByIdx],
         ["/item/{id}/", |Req req->Res?| { return Res("Item ${req.context['id']} requested" }],
         ["/item/{method}/{id}/", IndexView#]    
       }

There are three types of matching:

**Strict matching:**

  ::

    "/"
    "/orders/"
    "/some/app/edit"

  Number of slashed doesn't count here.

**Pathterm capturing:**

  ::

    "/orders/{id}/"
    "/orders/{id}/{action}/"

  In this case all urls starting with ``"orders"`` followed by one or two pathterms (any strings) will match (i.e. ``"/orders/1234/"``, ``"/orders/camcoder/"`` or ``"orders/x56/edit"``). Actual value for each capture arg will be stored in :attr:`Req.context` under name specified in curly braces.

  Additional regex may be specified to narrow match criteria::

    "/articles-by-year/{year:\\d{4}}/"

  In this case, ``"/articles-by-year/1985/"`` will match, but ``"/articles-by-year/100500/"`` will not. You can capture whole pathterm (string between two adjacent slashes) only.

**Tail matching:**

  ::

    "/files/*"

  If you specify ``/*`` at the end of URL, only beginnig of URL will be matched. The value of pathtail will be stored in :attr:`Req.context` under the name ``"pathTail"``. ``/*`` is allowed at the end of route only.

Passing views
-------------

You can pass any :class:`Turtle` instead of view function::

  router := Router {
    ["/", ViewClass#index],
    ["/comments", commentsAppTurtle],
    ...
  }

or you can include any turtle *instead* of route-view tuple::

  router := Router {
    ["/", ViewClass#index],
    commentsAppTurtle,
    ...
  }

.. note::

	Behind the scenes, :class:`Router` is a :class:`Selector`. It converts each tuple to :class:`UrlMatcherTurtle` which does exactly following:

	1. checks if current :attr:`Req.pathInfo` matches specified route path;
	2. if yes, populates :attr:`Req.context` with capture args from route path (if any), and calls view function;
	3. if no, returns ``null``, so next route may be tested.
	
	If there is a :class:`Turtle` instead of tuple in array, its :func:`~Trutle.dispatch` will be called.
