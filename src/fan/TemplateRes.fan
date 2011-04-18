
class TemplateRes : Res {
  Str template
  Str:Obj? context
  
  new make(Str template, Str:Obj? context := [:], Str:Obj options := [:]) : super (null, options) {
    this.template = template
    this.context = context
  }
  
  Bool isRendered() { return content != null }
}
