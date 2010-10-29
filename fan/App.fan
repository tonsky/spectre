
using web
using concurrent

const abstract class App {
  const Binding[] routes := [,]
  const TemplateLoader[] templateLoaders := [,]  
  const Charset charset := Charset.utf8
  
  virtual WebMod rootMod() {
    return RoutingMod.make(routes)
  }
  
  static Binding bind(Str url, Method controllerMethod) {
    controllerType := controllerMethod.parent
    if (!controllerType.fits(Controller#))
      throw Err.make("$controllerType must extend ViewController")
    m := Matcher.fromStr(url)
    return Binding.make(m, |->Controller| { controllerType.make }, controllerMethod.name)
  }
  
  static Binding bindC(Str url, Type controllerType, Str? method := "dispatch") {
    if (!controllerType.fits(Controller#))
      throw Err.make("$controllerType must extend ViewController")
    m := Matcher.fromStr(url)
    return Binding.make(m, |->Controller| { controllerType.make }, method)
  }

  static Binding bindB(Str url, |->Controller| controllerBuilder, Str? method := "dispatch") {
    m := Matcher.fromStr(url)
    return Binding.make(m, controllerBuilder, method)
  }

  static App instance() { Actor.locals["spectre.app"] }
  
  File appDir() { Actor.locals["spectre.app_dir"] }
  
  Obj? loadTemplate(Str name) {
    return templateLoaders.eachrWhile { it.load(name) }
  }
}
