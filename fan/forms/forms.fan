
mixin Form {
  spectre::Field[] fields() {
    this.typeof.fields.findAll { it.type.fits(spectre::Field#) }.map { it.get(this) }
  }
  
  Bool bind(Obj dataMap) { fields.map { it.bind(dataMap) }.all { it } }
  [Str:Obj] cleanedData() { Str:spectre::Field[:].addList(fields) |f| { f.name }.map { it.cleanedData } }  
  
  Str asTable() {
    fields.map { "<tr><th>" + it.label + "</th><td>" + it.renderErrors + it.renderHtml + "</td></tr>" }.join
  }
}