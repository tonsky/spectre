
class ToTemplate : Turtle {
  Str templateName
  Str:Obj? context
  Str:Obj resOptions
  
  new make(Str templateName, Str:Obj? context := [:], Str:Obj resOptions := [:]) {
    this.templateName = templateName
    this.context = context.ro
    this.resOptions = resOptions.ro
  }
  
  override Res? dispatch(Req req) { TemplateRes(templateName, context.dup, resOptions.dup) }
}
