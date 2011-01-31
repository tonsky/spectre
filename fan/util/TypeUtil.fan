
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
  
  ** Set params to target’s fields, converting them from Str if possible.
  ** Throws Err for incompartible fields.
  static Void assignFields(Obj target, Str:Obj? params, Bool checked := true) {
    params.each |v,k| {
      try {
        f := target.typeof.field(k)
        if (f != null) {
          if (v == null || v.typeof.fits(f.type))
            f.set(target, v)
          else if (v.typeof == Str#)
            f.set(target, TypeUtil.createFromStr(f.type, v))
          else
            throw Err("Cannot assign $v of type $v.typeof to field $f of type $f.type")
        }
      } catch (Err e) {
        if (checked)
          throw e
      }
    }
  }
}