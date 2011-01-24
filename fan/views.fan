
using web
using mustache

const mixin View {

  ** Used in error reporting
  abstract Obj caller()
  
  virtual Obj? tryMake(Type type, Req req) {
    constructor := type.method("make").func
    return tryCall(constructor, req)
  }
  
  virtual Obj? tryMethodCall(Method method, Obj instance, Req req) {
    tryCall(method.func.bind([instance]), req)
  }
  
  virtual Obj? tryCall(Func func, Req req) {
    paramValues := resolveParamValues(func.params, req)
    return func.callList(paramValues)
  }
  
  virtual Obj?[] resolveParamValues(Param[] params, Req req) {
    Obj?[] paramValues := [,]
    Param? defaultUsed := null
    
    for (idx := 0; idx < params.size; ++idx) {
      Param param := params[idx]
      
      resolved := req.context(param.name, false, NotResolved.instance)
      if (resolved === NotResolved.instance) {
        if (param.hasDefault) defaultUsed = param
        else throw ArgErr("Unmatched action param '$param.name' in $caller")
      } else {
        if (defaultUsed != null)
          throw ArgErr("Param '$param.name' cannot be set because '$defaultUsed.name'"
                     + " is using default value before him, in $caller")
        paramValues.add(resolved)
      }
    }
    
    return paramValues
  }
}

const class MethodView : View, Turtle {
  const Method method
  override Obj caller() { method }
  
  new make(Method method) { this.method = method }
  
  override Res? dispatch(Req req) {
    instance := tryMake(method.parent, req)
    return tryMethodCall(method, instance, req)
  }
}

const class FuncView : View, Turtle {
  const Func? func
  override Obj caller() { func }

  new make(Func func, |This|? f := null) { this.func = func.toImmutable; f?.call(this) }

  override Res? dispatch(Req req) {
    return tryCall(func, req)
  }
}

internal enum class NotResolved { instance }