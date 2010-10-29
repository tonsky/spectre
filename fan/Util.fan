
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
}
