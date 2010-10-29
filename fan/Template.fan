
using mustache

mixin TemplateLoader {
  abstract Obj? load(Str name)
}

const class MustacheTemplateLoader : TemplateLoader {
  const File[] lookupPaths
  const Str otag
  const Str ctag
  
  new make(File[] lookupPaths, Str otag := "{{", Str ctag := "}}") {
    this.lookupPaths = lookupPaths
    this.otag = otag
    this.ctag = ctag
  }
  
  override Obj? load(Str name) {
    nameUri := Uri.fromStr(name)
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
