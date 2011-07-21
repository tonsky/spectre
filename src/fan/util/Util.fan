
using concurrent

mixin Util {
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

  
  static [Obj:Obj?[]] groupby(Obj?[] list, |Obj?->Obj| groupKey) {
    [Obj:Obj[]] result := [:]
    result.ordered = true
    list.each { 
      gKey := groupKey.call(it)
      result.getOrAdd(gKey) { Obj[,] }.add(it)
    }
    return result
  }
  
  static [Str:Obj?][] flat(Obj:Obj? map, Str key := "key", Str value := "value") {
    return map.map |v,k| { [key: k, value: v] }.vals
  }
  
  static Map map(Obj?[][] list) {
    [Obj:Obj?] result := [:]
    list.each { result[it[0]] = it.size > 1 ? it[1] : null }
    return result
  }
  
  static Obj?[] sortby(Obj?[] vals, |Obj->Obj| key) {
    vals.rw.sort |a,b| { key(a) <=> key(b) }
  }
  
  static Obj?[] sortbyReverse(Obj?[] vals, |Obj->Obj| key) {
    vals.rw.sort |a,b| { key(b) <=> key(a) }
  }
  
  ** This function returns a list of tuples, where the i-th tuple contains 
  ** the i-th element from each of the argument sequences or iterables. 
  ** The returned list is truncated in length to the length of the shortest argument sequence. 
  ** With a single sequence argument, it returns a list of 1-tuples. 
  ** With no arguments, it returns an empty list.
  static Obj?[][] zip(Obj?[][] listOfLists) {
    i := 0
    res := Obj?[,]
    outOfEls := false
    
    while(true) {
      tuple := Obj?[,]
      for (x:=0; x<listOfLists.size; ++x) {
        if (i >= listOfLists[x].size) {
          outOfEls = true
          break
        }
        tuple.add((listOfLists[x])[i])
      }
      if (outOfEls) break
      res.add(tuple)
      ++i
    }    
    return res 
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

