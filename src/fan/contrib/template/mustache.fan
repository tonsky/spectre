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
    Log.get("spectre").info("Mustache templates are " + (options.get("useCache", false) ? "CACHED" : "NOT CACHED"))
    if (options.get("useCache", false))
      templatesCache = Cache(ActorPool())
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
  
  override MustacheToken partialToken(Str key, Str indentStr) { PartialToken(templateLoader, key, indentStr, otag, ctag) }  
  override MustacheToken defaultToken(Str content, Bool afterNewLine) { EscapedToken(content, otag, ctag, afterNewLine) }
}

internal const class EscapedToken : MustacheToken {
  const Str key
  const Str otag
  const Str ctag
  const Bool afterNewLine

  new make(Str key, Str otag, Str ctag, Bool afterNewLine) {
    this.key = key
    this.otag = otag
    this.ctag = ctag
    this.afterNewLine = afterNewLine
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    if (afterNewLine) output.add(indentStr)
    // TRICKY: According to specs lambda result expansion procedure expects standard 
    // double/triple mustache tags. It is not affected by currently set delimiter.
    Obj? value := format(valueOf(key, context, partials, callStack, indentStr, "{{", "}}", ""))
    if (value == null)
      return
    if (value is SafeStr)
      output.add(value)
    else {
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
  const Str partialIndent

  new make(TemplateLoader loader, Str key, Str partialIndent, Str otag, Str ctag) {
    this.loader = loader
    this.key = key
    this.partialIndent = partialIndent
    this.otag = otag
    this.ctag = ctag
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    Str? partialName := (valueOf(key.trim, context, partials, callStack, indentStr, "{{", "}}", "")?.toStr ?: key)?.trim
    if (partialName == null)
      throw Err("Partial ‘$key’ is not defined.")
    
    partial := loader.loadTemplate(partialName)
    callStack.insert(0, partial)
    output.add(partial.render(context, partials, callStack, indentStr+partialIndent))
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