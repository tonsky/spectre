
using printf

**
** Safe strings are used not to mess up with html escaping.
** Strings wrapped using `SafeStrUtil.escape` will be escaped only once,
** strigns wrapped with `SafeStrUtil.safe` will be not escaped and displayed as-is.
** 
** To create `SafeStr`ings, use `SafeStrUtil` mixin.
** 

class SafeStr {
  const Str escapedStr
  internal virtual Str _escape(Str val) {
    val.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;").replace("'", "&#39;")
  }
  internal new _make(|This| f) { f.call(this) }
  override Str toStr() { escapedStr }
  
  @Operator
  Str plusStr(Str str) { return toStr + str }
}

** 
** Include this mixin to create safe strings.
** 
** See `SafeStr`.
** 
mixin SafeStrUtil {
  static SafeStr safe(Obj? val) {
    val is SafeStr ? val : SafeStr._make { escapedStr = val }
  }
  
  static SafeStr escape(Obj? val) {
    val is SafeStr ? val : SafeStr._make { escapedStr = val == null ? "" : _escape(val) }
  }  
}

** 
** Formatter that takes care of format and arguments escaping.
** 
class SafeFormat: SafeStrUtil {
  static SafeStr printf(Obj format, Obj?[] args) {
    safe(Format.printf(escape(format).toStr, args.map { escape(it).toStr }))
  }
}