===========
 Templates
===========

Usually you'll need pages a little bit more complex than just a :class:`Str` with substitution variables. That's where you'll need templates.

Templates are simple text files (html, xml, csv, etc.) with special instructions in them. For now, spectre comes with built-in support for mustache templates only. You can find a really short introduction to musatche syntax `on their website <http://mustache.github.com/mustache.5.html>`_.

The recommended way to deal with templating is to return :class:`TemplateRes` object from the view and then intercept it and render in template rendering middleware. This decouples view from presentation details and leaves you a place to do something site-wide with :class:`TemplateRes` after it was returned from view (e.g. populate :attr:`~TemplateRes.context` with some site-wide attributes like current user's name, or change path to :class:`~TemplateRes.template` basing on client's platform, moving this logic out of view).

How to use templates
--------------------

First, create ``templates/`` folder somewhere inside your app's folder (it's just a convention, you are free to choose any name you want).

Set up renderer by wrapping your app with :class:`MustacheRenderer`::

  tempalteRenderer := MustacheRenderer { templateDirs = [appDir + `templates/`] }
  tempalteRenderer.wrap(router)

Then, create a template file inside ``templates/`` folder, for example ``index.html``::

  <h1>Hello from other world, {{name}}!</h1>
  You have just won ${{value}}!<br/>
  {{#in_ca}}
  Well, ${{taxed_value}}, after taxes.
  {{/in_ca}}
  
Finally, return :class:`TemplateRes` instead of :class:`Res` from view::

  Res index(Req req, Session session) {
    context := ["name": session["current_user"].name,
                "value": 200,
                "in_ca": true,
                "taxed_value": 15]
    return TemplateRes("index.html", context)
  }
  
When intercepted by :class:`MustacheRenderer`, :class:`TemplateRes` will be rendered using :attr:`TemplateRes.template` and :attr:`TemplateRes.context`, and result will be stored in :attr:`TemplateRes.content`. After that, :class:`TemplateRes` will be used as a typical :class:`Res` instance — returned from app, its content will be sent to the client.