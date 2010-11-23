using web::WebUtil

**
** Cookie models an HTTP cookie used to pass data between the server
** and brower as defined by the original Netscape cookie specification
** and RFC 2109.  Note the newer RFC 2965 is unsupported by most browsers,
** and even 2109 isn't really supported by some of the major browsers.
** See `Req.cookies` and `Res.setCookie`.
**
class Cookie {
  ** These strings cannot be used as cookie names
  internal static const Str[] reserved := ["expires", "path", "comment", "domain", "max-age", "secure", "version"]
  
  internal static const Str legalCharsPatt := Str<|\w\d!#%&'~_`><@,:/\$\*\+\-\.\^\|\)\(\?\}\{\=|>
  internal static const Regex cookiePatt := Regex.fromStr(
    "("                              // Start of group 'key'
    + "[" + legalCharsPatt + "]+?"   // Any word of at least one letter, nongreedy
    + ")"                            // End of group 'key'
    + "\\s*=\\s*"                    // Equal Sign
    + "("                            // Start of group 'val'
    + Str<|"[^;]*"|>                 // Any doublequoted string, ';' is not allowed inside string
    + "|"                            // or
    + "[\\ " + legalCharsPatt + "]*" // Any word (spaces allowed) or empty string
    + ")"                            // End of group 'val'
    + "\\s*;?"                       // Probably ending in a semi-colon
  )
  
  **
  ** Parse a HTTP 'Cookie' header.
  ** Throw ParseErr if not formatted correctly.
  **
  static Cookie[] load(Str s, |Str->Str| decode := Cookie#decode.func) {
    result := Cookie[,]
    Cookie? currentCookie
    
    m := cookiePatt.matcher(s)
    while(m.find) {
      k := m.group(1)
      v := m.group(2)
      
      if(k[0] == '$' || reserved.contains(k.lower)) {
        // TODO k is a Cookie attr name, set to corresponding field
        // if (currentCookie != null)
        //   Cookie#.field(k[1..-1]).set(currentCookie, v)
      } else {
        currentCookie = Cookie { name = k; val = decode.call(v) }
        result.add(currentCookie)
      }
    }
    
    return result
  }

  **
  ** Return the cookie formatted as an HTTP header.  The name must be a valid
  ** HTTP token and must not start with "$" (see `WebUtil.isToken`).
  ** The value string can be any string and will be encoded by `Cookie.encode`.
  **
  override Str toStr() {
    validateName
    
    s := StrBuf(64)
    s.add(name).add("=").add(encode(val))
    if (maxAge != null) {
      // we need to use Max-Age *and* Expires since many browsers
      // such as Safari and IE still don't recognize max-age
      s.add("; Max-Age=").add(maxAge.toSec)
      if (maxAge.ticks <= 0)
        s.add("; Expires=").add("Sat, 01 Jan 2000 00:00:00 GMT")
      else
        s.add("; Expires=").add((DateTime.nowUtc + maxAge).toHttpStr)
    }
    if (domain != null) s.add("; Domain=").add(domain)
    if (path != null) s.add("; Path=").add(path)
    if (secure) s.add("; Secure")
    return s.toStr
  }
  
  ** Name of the cookie.
  Str name := ""

  ** Value string of the cookie (unescaped).
  Str val := ""

  **
  ** Lifetime of this cookie, after max-age
  ** elapses the client should discard the cookie.  
  ** 
  ** If maxAge is null (the default) then the  cookie persists
  ** until the client is shutdown.  If zero is specified, the
  ** cookie is discarded immediately.  Note that many browsers
  ** still don't recognize max-age, so setting max-age also
  ** always includes an expires attribute.
  **
  Duration? maxAge

  **
  ** Domain for which the cookie is valid.
  ** An explicit domain must always start with a dot.  If
  ** null (the default) then the cookie only applies to
  ** the server which set it.
  **
  Str? domain

  **
  ** Subset of URLs to which the cookie applies.
  ** If set to "/" (the default), then the cookie applies to all
  ** paths.  If the path is null, it is assumed to be the same
  ** path as the document being described by the header which
  ** contains the cookie.
  **
  Str? path := "/"

  **
  ** If true, then the client only sends this cookie using a
  ** secure protocol such as HTTPS.  Defaults to false.
  **
  Bool secure := false

  internal static const Str legalChars := "abcdefghijklmnopqrstuvwxyz" 
    + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    + "0123456789"
    + Str<|!#$%&'*+-.^_`|~|>
  
  **
  ** Convert cookie value to quoted-string format.
  ** Chars 0..0x20 and 0x7e..0xff are encoded as '\xab'
  ** where 'ab' is a two-digit character's hex code.
  **   
  ** Chars 0x0100..0xffff are encoded as '\uabcd' 
  ** where 'abcd' is a four-digit character's hex code.
  ** 
  ** Some browsers do not support quoted-string from RFC 2109,
  ** including some versions of Safari and Internet Explorer.
  ** These browsers split on ';', and some versions of Safari
  ** are known to split on ', '.
  ** Therefore, we encode ';' and ',' using '\xab' scheme.
  **  
  ** '"' and '\' are escaped by adding single '\' before them.
  ** 
  ** Override this method to change encoding scheme (remember to
  ** support decoding too).
  **  
  virtual Str encode(Str from) {
    s := StrBuf(from.size)
    Bool addQuotes := false
    from.each |ch| { 
      if (ch < 0x20 || ch > 0x7e || ch == ';' || ch == ',')
        s.add(ch <= 0xff ? "\\x"+ch.toHex(2) : "\\u"+ch.toHex(4))
      else if (ch == '"' || ch == '\\')
        s.addChar('\\').addChar(ch)
      else
        s.addChar(ch)

      //TODO speedup containsChar call using table lookup
      if (!addQuotes && !legalChars.containsChar(ch))
        addQuotes = true
    }
    return addQuotes ? "\"" + s.toStr + "\"" : s.toStr
  }
  
  internal static const Regex hexPatt := Regex <|\\(x[0-9a-f]{2}|u[0-9a-f]{4})|>
  internal static const Regex quotePatt := Regex <|\\.|>
  
  **
  ** Decode quoted-string encoded by `Cookie.encode`
  **
  static Str decode(Str from) {
    if (from.size < 2)
      return from
    if (from[0] != '"' || from[-1] != '"')
      return from // string is unescaped — return as is
    from = from[1..-2] // no more quotes

    res := StrBuf(from.size)
    for (Int i := 0; i < from.size;) {
      tail := from[i..-1]
      hexMatch := hexPatt.matcher(tail)
      quoteMatch := quotePatt.matcher(tail)
      
      q := -1
      h := -1
      if (hexMatch.find) h = hexMatch.start
      if (quoteMatch.find) q = quoteMatch.start      
      if (q == -1 && h == -1) {
        res.add(tail)
        break
      }
      
      if (q != -1 && (h == -1 || q < h)) { // quotePatt matched before hexPatt
        res.add(tail[0..<q])
        res.addChar(tail[q+1])
        i = i + q + 2
      } else {                             // hexPatt matched
        res.add(tail[0..<h])
        res.addChar(Int.fromStr(tail[h+2..<hexMatch.end], 16))
        
        i = i + hexMatch.end
      }
    }
    return res.toStr
  }
  
  protected virtual Void validateName() {
    if (name.isEmpty)
      throw ArgErr("Cookie name cannot be empty")
    
    name.each |ch| { 
      if (!legalChars.containsChar(ch))
        throw ArgErr("Cookie name has illegal char '" + Str.fromChars([ch]) + "': $name")
    }

    if (reserved.contains(name.lower))
      throw ArgErr("'$name' is reserved and cannot be a cookie name")
  }
}