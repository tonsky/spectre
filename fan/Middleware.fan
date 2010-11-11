
abstract class Middleware : Turtle {
  Turtle child
  new make(Turtle child) { this.child = child }
  
  override Res? dispatch(Req req) {
    before(req)
    Res? res := child.dispatch(req)
    return after(req, res)
  }
  
  virtual Void before(Req req) {}
  virtual Res? after(Req req, Res? res) { 
    return res == null ? null : safeAfter(req, res)
  }
  virtual Res? safeAfter(Req req, Res res) { return res }
}

class GZip : Middleware {
  //FIXME remove, it's just a test
  new make(Turtle child) : super(child) {}
  
  override Res? safeAfter(Req req, Res res) {
    res.body = "[gzipped ${res.body.toStr}]"
    return res
  }
}