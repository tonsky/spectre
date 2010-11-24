
using web
using concurrent

**
** Descendant of this class is an entry point of web application
** 
abstract class Settings {
//  new make(File appDir) { this.appDir = appDir }
  
//////////////////////////////////////////////////////////////////////////
// Settings
//////////////////////////////////////////////////////////////////////////
  
//  File? appDir
  Turtle? root
  Charset charset := Charset.utf8  
  
//////////////////////////////////////////////////////////////////////////
// App instance
//////////////////////////////////////////////////////////////////////////
  
  static Settings instance() { Actor.locals["spectre.settings"] }
  static Void setInstance(Settings app) { Actor.locals["spectre.settings"] = app }
}