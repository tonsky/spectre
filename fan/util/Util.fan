
using concurrent

abstract class Util {
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

  static [Obj:Obj?[]] group(Obj?[] list, |Obj?->Obj| groupKey) {
    [Obj:Obj[]] result := [:]
    list.each { 
      gKey := groupKey.call(it)
      result.getOrAdd(gKey) { Obj[,] }.add(it)        
    }
    return result
  }
  
  **
  ** Find first file in dir (deep scanning) matching predicate
  ** 
  static File? findFirstFile(File dir, |File->Bool| predicate) {
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
  
  static Str xmlEscape(Str str) {
    return str.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;")
  }
  
}

