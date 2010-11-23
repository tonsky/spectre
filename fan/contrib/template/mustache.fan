using mustache

class MustacheRenderer : Middleware {
  File[] templateDirs
  const Str otag := "{{"
  const Str ctag := "}}"
  
  new make(|This|? f := null) : super() { f?.call(this) }
  
  override Res? safeAfter(Req req, Res res) {
    if (res is TemplateRes && !(res as TemplateRes).isRendered) {
      _res := res as TemplateRes
      _res.content = renderTemplate(_res.template, _res.context)
    }
    
    return res
  }
  
  virtual Str renderTemplate(Str templateName,
                     Str:Obj? context := [:]) {
    Mustache? template := loadTemplate(templateName)                 
    if (template == null)
      throw Err.make("Cannot find template $templateName in:\n  " + templateDirs.join("\n  "))
    return template.render(context)
  }
  
  virtual Mustache? loadTemplate(Str name) {
    nameUri := Uri.fromStr(name)
    File? path := templateDirs.find { (it + nameUri).exists }
    if (path == null)
      return null
    
    InStream templateIn := (path + nameUri).in
    
    return Mustache.forParser(MustacheParser { 
      it.in = templateIn
      it.partialTokenCreator = |Str key -> MustacheToken| {
        partial := loadTemplate(key)
        if (partial == null)
          throw ArgErr("Partial '$key' is not defined.")
        return SimplePartialToken(partial)
      }
    })
  }
}

internal const class SimplePartialToken : MustacheToken {
  const Mustache partial

  new make(Mustache partial) { this.partial = partial }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    output.add(partial.render(context, partials))
  }
}
