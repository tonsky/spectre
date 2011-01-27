
class TypeUtil {
  static Bool supports(Obj obj, Str slot) {
    return obj.typeof.slots.find { it.name == slot } != null
  }
  
  static Obj? createFromStr(Type type, Str str) {
    m := type.method("fromStr")
    if (!m.isStatic) throw Err("No static method 'fromStr' in $type")
    if (m.params.size > 1) throw Err("Too much params in ${type}.fromStr: ${m.params}")
    return m.call(str)
  }
}