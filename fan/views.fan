
using web
using mustache

mixin View {

  ** Used in error reporting
  abstract Obj caller
  
  virtual Obj? tryMake(Type type, Req req) {
    constructor := type.method("make").func
    return tryCall(constructor, req)
  }
  
  virtual Obj? tryMethodCall(Method method, Obj instance, Req req) {
    func := method.func//.bind([instance]) // because after bind param names are erased (1.0.56)
    paramValues := resolveParamValues(func.params[1..-1], req)
    return func.callList(paramValues.insert(0, instance))
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
      if(paramHasValue(param, req)) {
        if (defaultUsed != null)
          throw ArgErr("Param '$param.name' cannot be set because '$defaultUsed.name'"
                     + " is using default value before him, in $caller")
        
        paramValues.add(resolveParamValue(param, req))
      } else {
        if (param.hasDefault)
          defaultUsed = param
        else
          throw ArgErr("Unmatched action param '$param.name' in $caller
                        matches are ${req.context}")
      }
    }
    
    return paramValues
  }
  
  virtual Bool paramHasValue(Param param, Req req) {
    return param.type == Req# || req.context.containsKey(param.name)
  }
  
  virtual Obj? resolveParamValue(Param param, Req req) {
    if (param.type == Req#)
      return req
      
    if (req.context.containsKey(param.name)) {
      return req.context[param.name]
      // TODO maybe some intelligent conversion later
      
//      Str paramStr := req.context[param.name]
//      return param.type == Str# ? paramStr : param.type.method("fromStr").call(paramStr)
    }
    
    throw ArgErr("Unmatched action param '$param.name' in $caller
                  matches are ${req.context}")
  }
}

class MethodView : View, Turtle {
  Method method
  override Obj caller { get { method } }
  
  new make(Method method) { this.method = method }
  
  override Res? dispatch(Req req) {
    instance := tryMake(method.parent, req)
    return tryMethodCall(method, instance, req)
  }
}

class FuncView : View, Turtle {
  Func? func
  override Obj caller { get { func } }
  
  override Res? dispatch(Req req) {
    return tryCall(func, req)
  }
}

