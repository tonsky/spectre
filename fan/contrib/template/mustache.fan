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
    Mustache? template := SpectreMustacheParser.loadTemplate(templateName, this)                 
    if (template == null)
      throw Err.make("Cannot find template $templateName in:\n  " + templateDirs.join("\n  "))
    return template.render(context)
  }
  
  virtual InStream? templateIn(Str name) {
    nameUri := Uri.fromStr(name)
    File? path := templateDirs.find { (it + nameUri).exists }
    if (path == null)
      return null
    
    return (path + nameUri).in
  }
}

class SpectreMustacheParser : MustacheParser {
  MustacheRenderer templateLoader
  new make(|This|? f): super(f) {}

  static Mustache? loadTemplate(Str name, MustacheRenderer templateLoader) {
    in := templateLoader.templateIn(name)
    if (in == null)
      return null
    return Mustache.forParser(SpectreMustacheParser {
      it.in = in
      it.templateLoader = templateLoader
    })
  }
  
  override MustacheToken partialToken(Str key) {
    partial := loadTemplate(key.trim, templateLoader)
    if (partial == null)
      throw ArgErr("Partial '$key' is not defined.")
    return PartialToken(partial)
  }
  
  override MustacheToken defaultToken(Str content) { EscapedToken(content) }
}

internal const class EscapedToken : MustacheToken {
  const Str key

  new make(Str key) {
    this.key = key
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Obj? value := valueOf(key, context)
    if (value == null)
      return
    if (value is SafeStr) {
      output.add(value.toStr)
      return
    }
    Str str := value.toStr
    str.each {
      switch (it) {
        case '<': output.add("&lt;")
        case '>': output.add("&gt;")
        case '&': output.add("&amp;")
        default: output.addChar(it)
      }
    }
  }
}

internal const class PartialToken : MustacheToken {
  const Mustache partial

  new make(Mustache partial) { this.partial = partial }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    output.add(partial.render(context, partials))
  }
}
