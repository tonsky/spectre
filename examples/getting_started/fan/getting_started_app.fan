using spectre

class DemoApp : Settings {
  new make(Str:Obj? params) : super(params) {
    routes = Router {
      ["/", IndexView#index],
      ["/items/", ItemsView#list],
      ["/items/{itemId}/", ItemsView#edit],
    }
    renderer = MustacheRenderer([appDir + `templates/`])
  }  
}

class IndexView {
  Res index() {
    return Res("<html><body><h1>Hello from the other world!</h1>"
    + "<a href='/items/'>List of items</a></body></html>")
  }
}

class ItemsView {
  [Str:Obj][] items() {
    [["id": 1, "name": "Item 1"],
     ["id": 2, "name": "Item 2"],
     ["id": 3, "name": "Item 3"]]
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
      return ResRedirect(Uri.fromStr("/items/" + item["id"]
                                   + "/?message=" + Util.urlencode(message)))
    }

    Str message := req.get.get("message", "")

    return TemplateRes("item_edit.html", ["id":      item["id"],
                                          "name":    item["name"],
                                          "message": message])
  }
}