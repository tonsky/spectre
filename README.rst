=========
 Spectre
=========

Spectre is a general-purpose web application framework for `Fantom <http://fantom.org>`_ language.

Main features
-------------

* higly customizable;
* flexible url router;
* mustache templates for presentation layer;
* cookies;
* messages;
* pluggable session store support;
* full-featured forms processing library;
* development server with:

  * instant app reload;
  * WebSocket protocol draft 76 support;
  * static files serve ability.


Documentation
-------------

**Please take a look at doc/build/html/index.html**. It’s a complete documentation pack including usage examples, and it’s pretty nice, actually.

Sample application
------------------
::

	using spectre

	class DemoApp : Settings {
	  new make(File appDir) : super() {
	    routes := Router {
	      ["/", IndexView#index],
	      ["/items/", ItemsView#list],
	      ["/items/{itemId}/", ItemsView#edit],
	    }
    
	    tempalteRenderer := MustacheRenderer { templateDirs = [appDir + `getting_started/templates/`] }

	    root = Handler500().wrap(
	             Handler404().wrap(
	               tempalteRenderer.wrap(
	                 routes
	               )
	             )
	           )
	  }
	}


	class IndexView {
	  Res? index() {
	    return Res("<html><body><h1>Hello from the other world!</h1><a href='/items/'>List of items</a></body></html>")
	  }
	}

	class ItemsView {
	  [Str:Obj][] items() {
	    [["id": 1, "name": "Item 1"], ["id": 2, "name": "Item 2"], ["id": 3, "name": "Item 3"]]
	  }

	  TemplateRes list() {
	    return TemplateRes("items_list.html", ["items": items])
	  }
  
	  Res edit(Str itemId, Req req) {
	    Int _itemId := Int.fromStr(itemId)
	    item := items.find { it["id"] as Int == _itemId }
    
	    if (req.method == "POST") {
	      item["name"] = req.post["name"]
	      Str message := "Item ’" + item["name"] + "’ saved"
	      return ResRedirect(Uri.fromStr("/items/" + item["id"] + "/?message=" + Util.urlencode(message)))
	    }

	    Str message := req.get.get("message", "")

	    return TemplateRes("item_edit.html", ["id": item["id"], "name": item["name"], "message": message])
	  }
	}

For more examples take a look at `<http://bitbucket.org/xored/spectre_demo_app>`_.

Requirements
------------

* `fantom 1.0.57 <http://fantom.org>`_
* `printf <https://bitbucket.org/prokopov/printf>`_
* `mustache <https://bitbucket.org/xored/mustache>`_

