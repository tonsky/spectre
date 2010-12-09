
mixin Form: SafeStrUtil {
  Str[]? exclude() { null }
  Str[]? include() { null }
  
  Bool isIncluded(Str name) {
    include != null ? include.contains(name) : 
    (exclude != null ? !exclude.contains(name) : true)
  }
  
  spectre::Field[] fields() {
    this.typeof.fields.findAll { it.type.fits(spectre::Field#) && isIncluded(it.name) }.map { it.get(this) }
  }
  
  Bool bind(Obj dataMap) { fields.map { it.bind(dataMap) }.all { it } }
  [Str:Obj] cleanedData() { Str:spectre::Field[:].addList(fields) |f| { f.name }.map { it.cleanedData } }  
  
  SafeStr asTable() {
    safe(fields.map { "<tr><th>" + escape(it.label) + "</th><td>" + it.renderErrors + it.renderHtml + "</td></tr>" }.join)
  }
}