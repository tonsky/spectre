
class Set {
  Obj:Obj? impl := [:]
  This add(Obj el) { impl.set(el, null); return this }
  This addAll(Obj[] els) { els.each { add(it) }; return this }
  Bool contains(Obj el) { impl.containsKey(el) }
  Int size() { impl.size }
}
