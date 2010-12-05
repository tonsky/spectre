
using concurrent

abstract class Util
{
  const static Log log := Util#.pod.log
  
  **
  ** Find all duplicates in a collection
  **   
  static Obj?[] duplicates(Obj?[] l) {
    visited := [,]
    duplicates := [,]
    l.each {
      if (visited.contains(it)) {
        if (!duplicates.contains(it))
          duplicates.add(it)
      } else 
        visited.add(it)
    }
    return duplicates
  }

  **
  ** Find first file in dir (deep scanning) matching predicate
  ** 
  static File? findFirstFile(File dir, |File->Bool| predicate) {
    if (log.isDebug)
      log.debug("Scanning $dir")
    found := dir.listFiles.find(predicate)
    if (found != null)
      return found
    
    found = dir.listDirs.eachWhile { findFirstFile(it, predicate) }
    
    return found
  }
  
  static Str traceToStr(Err err, Int maxDepth := 1000) {
    buf := StrBuf() 
    err.trace(buf.out, ["maxDepth": 1000])
    return buf.toStr
  }
  
  static Str captureStr(InStream in) {
    buf := StrBuf()
    in.pipe(buf.out)
    return buf.toStr
  }
  
  static Str urlencode(Str str) {
    return str.replace(";", "\\;").replace("=", "\\=").replace("&", "\\&")
  }
  
  static Bool supports(Obj obj, Str slot) {
    return obj.typeof.slots.find { it.name == slot } != null
  }
}

