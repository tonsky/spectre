using util

class StartApp : AbstractMain {
  @Arg { help = "name of your app (dir with this name will be created in current dir)" }
  Str? newappname
  
  override Int run() {
    pod := Pod.of(this)
    checking := File(`$newappname`, false)
    if (checking.exists) {
      echo("Cannot create app. Path ${checking.normalize.pathStr} already exists.")
      return 1
    }
      
    newappdir := File(`./`).createDir(newappname)
    
    files := [
      pod.file(`/res/startapp/build.fan`): `build.fan`,
      pod.file(`/res/startapp/app.fan`): `fan/app.fan`,
      pod.file(`/res/startapp/index.html`): `templates/index.html`,
      pod.file(`/res/startapp/favicon.gif`): `static/favicon.gif`,
      pod.file(`/res/startapp/newappname.css`): `static/${newappname}.css`,]

    
    files.each |t, f| {
      target := newappdir + t
      if (f.ext != "gif") {
        content := f.readAllStr.replace("newappname", newappname).replace("Newappname", newappname.capitalize)
        target.out.writeChars(content).close
      } else
        f.copyTo(target)
    }
    return 0
  }
}
