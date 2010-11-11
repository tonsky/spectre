Spectre
=======

Requires  
* [mustache](https://github.com/vspy/mustache)  
* [fantom 1.0.56](http://fantom.org)  

Sample application
==================

spectre_webapp.fan
------------------
    using spectre

    class SpectreWebapp : Settings {
      new make(File appDir) : super(appDir) {
        routes := Router { routes([
          ["/", IndexView#index],
          ["/items/", IndexView#items],
          ["/item/{idx:\\d+}", IndexView#itemByIdx],
          ["/err/", BrokenView#err],
          ["/static/*", StaticView.make(appDir + `static/`)]
        ])}

        root = Handler500 { child = 
          Handler404 { child = 
            routes
          }
        }
    
        templateDirs = [
          appDir + `templates/`
        ]
      }
    }

    
views.fan
---------
    using spectre

    class IndexView : MustacheTemplates {
      Res index() {
        return renderToResponse("index.html", ["title":"Hi there"])
      }
  
      Res items() {
        return renderToResponse("items.html", ["items": ["Alice", "Bob", "Charlie"],
                                               "title": "Items list page"])
      }
  
      Res item(Str id) {
        return renderToResponse("item.html", ["id": id, "title": "Item page $id"])
      }
  
      Res itemByIdx(Int idx) {
        item = "item"
        return Res(
          "<a href='/'>Index</a> → <a href='/items/'>Items</a> → <strong>item [$idx]</strong>"
          + "<h1>Item page</h1>" + item
          + "<br/><br/><a href='/'>Back to main</a>")
      }
    }

    class BrokenView {
      Res err() {
        throw Err.make("Hi there!")
      }
    }

How to ru(i)n it
----------------
    >>> fan spectre/build.fan
    >>> fan spectre::WispServer spectre_webapp/

Where `spectre_webapp/` is a path to your application home dir with `build.fan` in it