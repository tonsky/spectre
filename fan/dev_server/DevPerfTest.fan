using concurrent
using util
using web

class DevPerfTest : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run() {
    return runServices([ WebServer { it.port = this.port; protocols = [PerfTestHttpProtocol()] } ])
  }
}

const class PerfTestHttpProtocol : HttpProtocol {
  private const static Log log := Log.find("spectre")
  
  override Bool onRequest(HttpReq httpReq, OutStream out) {
    resp := "Hello world #4"
    status := 200
    
    out.print("HTTP/1.1 ")
       .print(status)
       .print(" ")
       .print(WebRes.statusMsg[status])
       .print("\r\n");
    
    out.print("Content-Type: text/plain; charset=utf8\r\n")
    out.print("Content-Lenght: " + resp.size + "\r\n")
    
    if (httpReq.version === HttpReq.ver10 && "keep-alive".equalsIgnoreCase(httpReq.headers.get("Connection", "")))
      out.print("Connection: keep-alive\r\n")
    
    out.print("\r\n")
    
    cout := WebUtil.makeFixedOutStream(out, resp.size)
    cout.print(resp)
    
    return true
  }
}
