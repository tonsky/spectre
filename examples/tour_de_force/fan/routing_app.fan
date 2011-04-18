
using spectre

class RoutingApp : Router {
  new make() : super() {
    add(["/routing/", RoutingViews#index])
    add(["/routing/{year:\\d{4}}/", RoutingViews#byYear])
    add(["/routing/{group}/", RoutingViews#byGroup])
    add(["/routing/{group}/{id}/", RoutingViews#byId])          
  }
}

const class Article {
  const Int id
  const Str name
  const Str group
  const Int year
  
  new make(Int id, Str name, Str group, Int year) {
    this.id = id
    this.name = name
    this.group = group
    this.year = year
  }
}

class RoutingViews {
  static const Article[] articles := [
    Article(1, "IT Article 1", "it", 2009),
    Article(2, "IT Article 2", "it", 2010),
    Article(3, "Phoot Article 1", "photo", 2009),
    Article(4, "Phoot Article 2", "photo", 2010),
  ]
  
  [Str:Str][] toMap(Article[] arr) {
    return arr.map { ["id": it.id, "name": it.name, "group": it.group, "year": it.year] }
  }
  
  virtual Res index() {
    return TemplateRes("routing.html", ["articles": toMap(articles)])
  }

  virtual Res byGroup(Str group) {
    articles := articles.findAll { it.group == group }
    return TemplateRes("routing.html", ["articles": toMap(articles)])
  }
  
  virtual Res byId(Str group, Str id) {
    articles := articles.findAll { it.group == group && it.id == Int.fromStr(id) }
    return TemplateRes("routing.html", ["articles": toMap(articles)])
  }
  
  virtual Res byYear(Str year) {
    articles := articles.findAll { it.year == Int.fromStr(year) }
    return TemplateRes("routing.html", ["articles": toMap(articles)])
  }
}