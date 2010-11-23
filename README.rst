=========
 Spectre
=========

Requires:

* `mustache <https://github.com/vspy/mustache>`_
* `fantom 1.0.56 <http://fantom.org>`_

Sample application
==================

spectre_webapp.fan
------------------
::

    using spectre

    
    class SpectreWebapp : Settings {
      new make(File appDir) : super(appDir) {
        routes := Router { routes([
          ["/", TestView#index],
          ["/items/", IndexView#items],
          ["/item/{idx:\\d+}", IndexView#itemByIdx],
          ["/item/{id}/", |Req req2, Str id->Res?| { IndexView.make.item(id) }], //won't work
          ["/item/{method}/{id}/", IndexView#], //won't work either

          ["/set-cookie/", TestView#setCookie],
          ["/delete-cookie/", TestView#deleteCookie],

          ["/init-session/", TestView#initSession],
          ["/change-session/", TestView#changeSession],
          ["/clear-session/", TestView#clearSession],

          ["/err/", BrokenView#err],

          ["/static/*", StaticView.make(appDir + `static/`)]
        ])}

        root = Handler500 { child = 
          Handler404 { child = 
            SessionMiddleware(routes) {
              sessionStore = InmemorySessionStore { 
                maxSessionAge = Duration.fromStr("5sec")
                cleanupPeriod = Duration.fromStr("3sec")
              }
            }
          }
        }

        templateDirs = [
          appDir + `templates/`
        ]
      }
    }

    
views.fan
---------
::

    using spectre

    class TestView : MustacheTemplates {
      Res index(Req req) {
        session := req.context["session"]
        context := ["title":"Hi there", "cookies": req.cookies, "session": session]
        res := renderToResponse("index.html", context)
        res.setCookie(Cookie { name = "z"; val = "index"/*; maxAge = Duration.fromStr("1day")*/ })
          .setCookie(Cookie { name = "secondcookie"; val = "b"/*; maxAge = Duration.fromStr("1day")*/ })
          .setCookie(Cookie { name = "thirdcookie"; val = "c"/*; maxAge = Duration.fromStr("1day")*/ })
        return res
      }

      Res initSession(Req req) {
        Session session := req.context["session"]
        session["test"] = "test_value"

        return ResRedirect(`/`)
      }

      Res changeSession(Req req, Session session) {
        session.set("test", "changed_value")

        return ResRedirect(`/`)
      }

      Res clearSession(Req req, Session session) {
        session.delete
        return ResRedirect(`/`)
      }

      virtual Res setCookie(Req req) {
        res := ResRedirect(`/`)
          .setCookie(Cookie { name = req.get["cookie-name"]; val = req.get["cookie-value"]/*; maxAge = Duration.fromStr("1day")*/ })
          .setCookie(Cookie { name = "secondcookie"; val = "b"/*; maxAge = Duration.fromStr("1day")*/ })
          .setCookie(Cookie { name = "thirdcookie"; val = "c"/*; maxAge = Duration.fromStr("1day")*/ })

        res.headers["Content-Length"] = "1400"
    //    res.headers["Connection"] = "close"

        return res
      }

      virtual Res deleteCookie(Req req) {
        return ResRedirect(`/`).deleteCookie(req.get["cookie-name"])
      }
    }

    class BrokenView {
      Res err() {
        throw Err.make("Hi there!")
      }
    }

How to ru(i)n it
----------------
::

    >>> fan spectre/build.fan
    >>> fan spectre::WispServer spectre_demo_app/

Where ``spectre_demo_app/`` is a path to your application home dir with ``build.fan`` in it.