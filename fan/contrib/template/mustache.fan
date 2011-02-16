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
      throw Err.make("Cannot find template ‘$name’ in:\n " + templateDirs.join("\n "))
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
  
  ** Avaliable options: 
  ** * useCache: true/false
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
  
  override MustacheToken partialToken(Str key) { PartialToken(templateLoader, key, otag, ctag) }  
  override MustacheToken defaultToken(Str content) { EscapedToken(content, otag, ctag) }
}

internal const class EscapedToken : MustacheToken {
  const Str key
  const Str otag
  const Str ctag

  new make(Str key, Str otag, Str ctag) {
    this.key = key
    this.otag = otag
    this.ctag = ctag
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Mustache[] callStack) {
    Obj? value := valueOf(key, context, partials, callStack, "")
    if (value == null)
      return
    if (value is SafeStr) {
      output.add(value)
      return
    }
    Str str := value.toStr
    str.each {
      switch (it) {
        case '<': output.add("&lt;")
        case '>': output.add("&gt;")
        case '&': output.add("&amp;")
        case '"': output.add("&quot;")
        case '\'': output.add("&#39;")
        default: output.addChar(it)
      }
    }
  }
  override Str templateSource() {
    b := StrBuf()
    b.add(otag)
    b.add(key)
    b.add(ctag)
    return b.toStr
  }
}
internal const class PartialToken : MustacheToken {
  const TemplateLoader loader
  const Str key
  const Str otag
  const Str ctag  

  new make(TemplateLoader loader, Str key, Str otag, Str ctag) {
    this.loader = loader
    this.key = key
    this.otag = otag
    this.ctag = ctag
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Mustache[] callStack) {
    Str? partialName := valueOf(key.trim, context, partials, callStack, "") ?: key.trim
    if (partialName == null)
      throw Err("Partial ‘$key’ is not defined.")
    
    partial := loader.loadTemplate(partialName.trim)
    callStack.insert(0, partial)
    output.add(partial.render(context, partials, callStack))
    callStack.removeAt(0)
  }

  override Str templateSource() {
    b := StrBuf()
    b.add(otag)
    b.add(">")
    b.add(key)
    b.add(ctag)
    return b.toStr
  }
}