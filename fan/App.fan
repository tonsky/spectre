
using web
using concurrent

const abstract class App {
  const Binding[] routes := [,]
  const File[] templateDirs := [,]  
  const Charset charset := Charset.utf8

//////////////////////////////////////////////////////////////////////////
// App instance
//////////////////////////////////////////////////////////////////////////
  
  static App instance() { Actor.locals["spectre.app"] }
  File appDir() { Actor.locals["spectre.app_dir"] }

//////////////////////////////////////////////////////////////////////////
// URL binding
//////////////////////////////////////////////////////////////////////////
  
  static Binding bind(Str url, Method controllerMethod) {
    controllerType := controllerMethod.parent
    m := Matcher.fromStr(url)
    return Binding.make(m, |->Obj| { controllerType.make }, controllerMethod.name)
  }
  
  static Binding bindC(Str url, Type controllerType, Str? method := "dispatch") {
    m := Matcher.fromStr(url)
    return Binding.make(m, |->Obj| { controllerType.make }, method)
  }

  static Binding bindB(Str url, |->Obj| controllerBuilder, Str? method := "dispatch") {
    m := Matcher.fromStr(url)
    return Binding.make(m, controllerBuilder, method)
  }
}
