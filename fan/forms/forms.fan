
class Form: SafeStrUtil {

  virtual Obj[] errors := [,]
  virtual Void validate() {}

  virtual Bool bind(Obj dataMap) {
    if (!fields.map { it.bind(dataMap) }.all { it })
      return false
    validate
    return errors.isEmpty
  }
  
  virtual Bool isValid() { errors.isEmpty && fields.all { it.isValid } }
  
  virtual Str[]? exclude() { null }
  virtual Str[]? include() { null }
  
  virtual Bool isIncluded(Str name) {
    include != null ? include.contains(name) : 
    (exclude != null ? !exclude.contains(name) : true)
  }
  
  virtual spectre::Field[] fields() {
    this.typeof.fields.findAll { it.type.fits(spectre::Field#) && isIncluded(it.name) }.map { it.get(this) }
  }
  
  virtual [Str:Obj?] cleanedData() { Str:spectre::Field[:].addList(fields) |f| { f.name }.map { it.cleanedData } }  
  
  virtual SafeStr asTable() {
    safe(
      (errors.isEmpty ? "" : "<tr class=\"form_errorrow\"><td colspan=\"2\">${renderErrors}</td></tr>")
      + fields.map {
        "<tr" + (it.isBound && !it.isValid ? " class=\"errorrow\"" : "") + "><th>"
          + it.renderLabel
        + "</th><td>"
          + it.renderErrors
          + it.renderHtml
        + "</td></tr>"
      }.join
    )
  }
  
  virtual SafeStr renderErrors() {
    safe(errors.isEmpty ? "" : "<ul class=\"errorlist\"><li>" + errors.map { escape(it) }.join("</li><li>") + "</li></ul>")
  }
}