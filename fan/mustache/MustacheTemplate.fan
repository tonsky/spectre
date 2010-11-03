using mustache

mixin MustacheTemplates { 
  static const MustacheTemplateLoader loader := MustacheTemplateLoader.make
  
  Str renderTemplate(Str templateName,
                     Str:Obj? context := [:],
                     Int statusCode := 200,
                     Str contentType := "text/html") {
    Mustache? template := loader.load(templateName)                 
    if (template == null)
      throw Err.make("Cannot find template $templateName")
    return template.render(context)
  }
  
  HttpRes renderToResponse(Str templateName,
                           Str:Obj? context := [:],
                           Int statusCode := 200,
                           Str contentType := "text/html") {
    return HttpRes.make(renderTemplate(templateName, context), statusCode, contentType)
  }
}


const class MustacheTemplateLoader : TemplateLoader {
  const Str otag
  const Str ctag
  
  new make(Str otag := "{{", Str ctag := "}}") {
    this.otag = otag
    this.ctag = ctag
  }
  
  override Obj? load(Str name) {
    nameUri := Uri.fromStr(name)
    lookupPaths := App.instance.templateDirs
    File? path := lookupPaths.find { (it + nameUri).exists }
    if (path == null)
      return null
    
    InStream templateIn := (path + nameUri).in
    
    return Mustache.forParser(MustacheParser { 
      it.in = templateIn
      it.partialTokenCreator = |Str key -> MustacheToken| {
        SimplePartialToken.make(key, this)
      }
    })
  }
}

internal const class SimplePartialToken : MustacheToken {
  const Mustache? partial

  new make(Str key, MustacheTemplateLoader tl) {
    partial = tl.load(key)
    if (partial == null)
      throw ArgErr("Partial '$key' is not defined.")
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    output.add(partial.render(context, partials))
  }
}
