using mustache
using concurrent

const class TemplateLoader {
  const File[] templateDirs
  new make(File[] templateDirs) { this.templateDirs = templateDirs }
  
  virtual InStream? templateIn(Str name) {
    nameUri := Uri.fromStr(name)
    File? path := templateDirs.find { (it + nameUri).exists }
    if (path == null)
      return null
    
    return (path + nameUri).in
  }

  Mustache loadTemplate(Str name) {
    in := templateIn(name)
    if (in == null)
      throw Err.make("Cannot find template ’$name’ in:\n " + templateDirs.join("\n "))
    return Mustache.forParser(SpectreMustacheParser {
      it.in = in
      it.templateLoader = this
    })
  }
}

class MustacheRenderer : Middleware {
  const Str otag := "{{"
  const Str ctag := "}}"
  const TemplateLoader loader
  const Cache? templatesCache
  
  **
  ** Avaliable options: 
  ** * useCache: true/false
  ** 
  new make(File[] templateDirs, Str:Obj? options := [:], |This|? f := null) : super() { 
    loader = TemplateLoader(templateDirs)
    if (options.get("useCache", false))
      templatesCache := Cache(ActorPool())
    f?.call(this)
  }
  
  override Res? safeAfter(Req req, Res res) {
    if (res is TemplateRes && !(res as TemplateRes).isRendered) {
      _res := res as TemplateRes
      _res.content = renderTemplate(_res.template, _res.context)
    }
    return res
  }
  
  virtual Str renderTemplate(Str name, Str:Obj? context := [:]) {
    Mustache template := templatesCache == null ?
      loader.loadTemplate(name) :
      templatesCache.getOrAdd(name) |->Obj?| { loader.loadTemplate(name) }
    return template.render(context)
  }
}

class SpectreMustacheParser : MustacheParser {
  TemplateLoader templateLoader
  new make(|This|? f): super(f) {}
  
  override MustacheToken partialToken(Str key) { PartialToken(key, templateLoader) }
  
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
        case '"': output.add("&quot;")
        case ''': output.add("&#39;")
        default: output.addChar(it)
      }
    }
  }
}

internal const class PartialToken : MustacheToken {
  const Str key
  const TemplateLoader loader
  
  new make(Str key, TemplateLoader loader) {
    this.key = key
    this.loader = loader
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Str? partialName := valueOf(key.trim, context) ?: key
    if (partialName == null)
      throw Err("Partial '$key' is not defined.")
    
    partial := loader.loadTemplate(partialName.trim)
    output.add(partial.render(context, partials))
  }
}
