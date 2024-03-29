**
** A map with support of multiple values for key, [Str:Str[]]
** 
class QueryMap {
  const static Log log := Log.get("spectre")
  internal [Str:Str[]] impl

//////////////////////////////////////////////////////////////////////////
// Adapters
//////////////////////////////////////////////////////////////////////////
  
  **
  ** Return read-only view of this as Map
  ** 
  Str:Str asMap() { impl.map { chooseVal(it) }.ro }
  
  **
  ** Return read-only view of this as a [Str:Str[]] Map
  ** 
  [Str:Str[]] asMultimap() { impl.ro }

  **
  ** Converts ["a": [1, 2, 3], "b": [4, 5]] to [["a", 1], ["a", 2], ["a", 3], ["b", 4], ["b", 5]]
  ** 
  Str[][] asList() { 
    Str[][] res := [,]
    impl.each |vals, k| { vals.each |val| { res.add([k, val]) } }
    return res
  }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  
  **
  ** Create an instance from map with Str or Str[] values
  **   
  new make([Str:Obj] values := [:]) {
    this.impl = [Str:Str[]] [:] { ordered = true }
    values.each |Obj v, Str k| {
      if (v is Str[])
        setList(k, v)
      else if (v is Str)
        set(k, v)
      else
        throw Err.make("Query map can only contain Str or Str?[]: " + v.typeof)
    }
  }

  private new makeWith([Str:Str[]] impl) { this.impl = impl }
  private Str[] wrapToList(List l) { Str[,].addAll(l) }
  private Str? chooseVal(Str[]? valList, Str? _def := "") { valList == null ? null : valList.getSafe(-1, _def) }
  
//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  override Bool equals(Obj? that) { 
    that == null ? false : (that is QueryMap ? impl.equals((that as QueryMap).impl) : false)
  }

  override Int hash() { impl.hash }

  Bool isEmpty() { impl.isEmpty }

  **
  ** Get the number of key/value pairs in the list.
  **
  Int size() { impl.size }

  **
  ** Return mapped value for existing keys, "" for mapped keys without values,
  ** _def or this.def for unmapped keys. Shortcut is 'a[key]'.
  ** If there's a list of values mapped to the key, this method returns last value.  
  ** >>> qm := QueryMap.make(["a": ["b", "c", "d"], "e": "f"])
  ** >>> qm.get("a") // returns the last
  ** "d"
  ** >>> qm.get("e", "def")
  ** "f"
  ** >>> qm.get("x")
  ** null
  ** >>> qm.def = "def"
  ** >>> qm.get("x")
  ** "def"  
  ** >>> qm.get("x", "local_def")
  ** "local_def"
  **
  @Operator
  Str? get(Str key, Str? _def := null) {
    Str[]? res := impl.get(key)
    return res == null ? _def : chooseVal(res)
  }

  **
  ** Same as `get`, but return all values mapped to the key as a list.
  ** For keys mapped to empty values returns [""]
  ** >>> qm := QueryMap.make(["a": ["b", "c", "d"], "e": "f"])
  ** >>> qm.getList("a")
  ** ["b", "c", "d"]
  ** >>> qm.getList("e")
  ** ["f"]
  ** >>> qm.getList("x")
  ** null
  **
  Str[]? getList(Str key, Str[]? _def := null) { impl.get(key, _def) }

  Bool containsKey(Str key) { impl.containsKey(key) }
  
  **
  ** Create a shallow duplicate copy of this QueryMap. The keys and
  ** values themselves are not duplicated.
  **
  This dup() { QueryMap.makeWith(impl.dup) }

  **
  ** Set the value for the specified key.  If the key is already
  ** mapped, this overwrites the old value.  If key is not yet mapped
  ** this adds the key/value pair to the map.  Return this.  If key
  ** does not return true for Obj.isImmutable, then throw NotImmutableErr.
  ** If key is null throw NullErr.  Throw ReadonlyErr if readonly.
  ** Shortcut is 'a[key] = val'.
  **
  @Operator
  This set(Str key, Str val) { impl[key] = Str[val]; return this }

  **
  ** Same as `set`, but maps list of values to a single key.
  ** 
  This setList(Str key, Str[] val) { impl[key] = wrapToList(val); return this }

  **
  ** Add the specified key/value pair to the map.  If the key is
  ** already mapped, new values are added to the end.  Return this.  If key
  ** does not return true for Obj.isImmutable, then throw NotImmutableErr.
  ** If key is null throw NullErr.  Throw ReadonlyErr if readonly.
  **
  This add(Str key, Str val) {
    if (impl.containsKey(key))
      impl[key].add(val)
    else
      set(key, val)
    return this    
  }

  **
  ** Same as `add`, but maps list of values to a single key.
  ** 
  This addList(Str key, Str[] val) {
    if (impl.containsKey(key))
      impl[key].addAll(val)
    else
      setList(key, val)
    return this
  }

  **
  ** Append the specified map to this map by setting every key/value in
  ** m in this map.  Keys in m not yet mapped are added and keys already
  ** mapped are overwritten.  Return this.  Throw ReadonlyErr if readonly.
  ** Also see `addAll`.
  **
  This setAll([Str:Str] map) { map.each |v,k| { this.set(k, v) }; return this }

  **
  ** Same as `setAll`, but for lists values
  ** 
  This setAllList([Str:Str[]] map) { map.each |v,k| { this.setList(k, v) }; return this }
  
  **
  ** Same as `setAll`, but for QueryMap
  ** 
  This setAllMap(QueryMap map) { setAllList(map.impl) }

  **
  ** Append the specified map to this map by adding every key/value in
  ** m in this map.  If any key in m is already mapped then this method
  ** will fail (any previous keys will remain mapped potentially leaving
  ** this map in an inconsistent state).  Return this.  Throw ReadonlyErr if
  ** readonly.  Also see `setAll`.
  **
  This addAll([Str:Str] map) { map.each |v,k| { this.add(k, v) }; return this }

  **
  ** Same as `addAll`, but for lists values
  ** 
  This addAllList([Str:Str[]] map) { map.each |v,k| { this.addList(k, v) }; return this }
  
  **
  ** Same as `addAll`, but for QueryMap
  **
  This addAllMap(QueryMap map) { addAllList(map.impl) }

  **
  ** Remove the key/value pair identified by the specified key
  ** from the map and return the value (last value if mapped to list).
  ** If the key was not mapped then return null. Throw ReadonlyErr if readonly.
  **
  Str? remove(Str key) { Str[]? list := impl.remove(key); return list == null ? null : chooseVal(list) }

  **
  ** Same as `remove` but returns all values mapped to key as list.
  **
  Str[]? removeList(Str key) { impl.remove(key) }

  **
  ** Remove all key/value pairs from the map.  Return this.
  ** Throw ReadonlyErr if readonly.
  **
  This clear() { impl.clear; return this }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a string representation the Map.  This method is readonly safe.
  **
  override Str toStr() { "<QueryMap ${impl.toStr}>" }

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  Bool isRO() { impl.isRO }

  Bool isRW() { impl.isRW }

  This ro() { isRO ? this : QueryMap.makeWith(this.impl.ro) }

  This rw() { isRW ? this : QueryMap.makeWith(this.impl.rw) }

  
//////////////////////////////////////////////////////////////////////////
// URI
//////////////////////////////////////////////////////////////////////////

  //FIXME does it really belongs here?
  
  **
  ** Translate this into percent encoded form
  **   
  Str encode() { return encodeQuery(impl) }
  
  **
  ** Translate map into percent encoded form
  **   
  static Str encodeQuery([Str:Str[]] map) {
    StrBuf buf := StrBuf.make
    map.each |Str[] vals, Str key| {
      vals.each |Str val| {
        if (buf.size > 0)
          buf.addChar('&')
        buf.add(Uri.encodeQuery([key: val]))  
      }
    }
    return buf.toStr
  }

  **
  ** Decode query parameters which are URL encoded according
  ** to the "application/x-www-form-urlencoded" MIME type.  This method
  ** will unescape '%' percent encoding and '+' into space.  Throw
  ** ArgErr is the string is malformed.  See `encodeQuery`.
  **
  static QueryMap decodeQuery(Str? q) {
    map := QueryMap()
    if (q == null)
      return map

    try {
      start := 0
      eq := 0
      len := q.size
      prev := 0
      hasEscapes := false
      
      for (i := 0; i < len; ++i) {
        ch := q[i]
        if (prev != '\\') {
          if (ch == '=')
            eq = i
          if (ch != '&' && ch != ';') {
            prev = ch
            continue
          }
        } else {
          hasEscapes = true
          prev = (ch != '\\') ? ch : 0
          continue
        }

        if (start < i) {
          addQueryParam(map, q, start, eq, i, hasEscapes)
          hasEscapes = false
        }

        start = eq = i+1
      }

      if (start < len)
        addQueryParam(map, q, start, eq, len, hasEscapes)
    } catch (Err e) {
      // don't let internal error bring down whole uri
      log.err("Error parsing uri", e) 
    }

    return map
  }
  
  private static Void addQueryParam(QueryMap map, Str q, Int start, Int eq, Int end, Bool hasEscapes) {
    Str? key
    Str? val
    if (start == eq && q[start] != '=') {
      key = toQueryStr(q, start, end, hasEscapes)
      val = ""
    } else {
      key = toQueryStr(q, start, eq, hasEscapes)
      val = toQueryStr(q, eq+1, end, hasEscapes)
    }

    map.setList(key, map.getList(key, Str?[,]).add(val))
  }
  
  private static Str toQueryStr(Str q, Int start, Int end, Bool hasEscapes) {
//    if (!hasEscapes)
//      return q[start..<end]
    s := StrBuf.make(end-start)
    escaping := false
    for (i := start; i < end;) {
      Int[] res := nextChar(q, i)
      Int c := res[0]
      
      if (c == '\\' && res[1] - i == 1) {
        if (escaping) {
          s.addChar(c)
          escaping = false
        } else
          escaping = true
      } else {
        s.addChar(c)
        escaping = false
      }
      
      i = res[1]
    }
    return s.toStr
  }

  
  internal static Int[] nextChar(Str arg, Int startPos) {
    Int[] res := nextOctet(arg, startPos)
    Int c := res[0]
    Int pos := res[1]
    
    switch(c.shiftr(4)) {
      case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
        /* 0xxxxxxx*/
        return [c, pos]
      case 12: case 13:
        /* 110x xxxx   10xx xxxx*/
        res = nextOctet(arg, pos)
        Int c2 := res[0]
        pos = res[1]
      
        if (c2.and(0xC0) != 0x80)
          throw ParseErr("Invalid UTF-8 encoding at $startPos: " + arg[startPos..<pos]);
        return [c.and(0x1F).shiftl(6).or(c2.and(0x3F)), pos]
      case 14:
        /* 1110 xxxx  10xx xxxx  10xx xxxx */
        res = nextOctet(arg, pos)
        Int c2 := res[0]
        pos = res[1]
      
        res = nextOctet(arg, pos)
        Int c3 := res[0]
        pos = res[1]

        if (c2.and(0xC0) != 0x80 || c3.and(0xC0) != 0x80)
          throw ParseErr("Invalid UTF-8 encoding at $startPos: " + arg[startPos..<pos]);
        return [c.and(0x0F).shiftl(12).or(c2.and(0x3F).shiftl(6)).or(c3.and(0x3F)), pos]
      default:
        return [c, pos]
//        throw ParseErr("Invalid UTF-8 encoding at $startPos: " + arg[startPos..<pos]);
    }
  }
  
  internal static Int[] nextOctet(Str arg, Int pos) {
    c := arg[pos++]
    if (c == '%') {
      if(arg.size < pos+2)
        throw ParseErr("Invalid char at " + (pos-1) + ": " + arg[pos-1..-1])

      d1 := arg[pos++].fromDigit(16)
      d2 := arg[pos++].fromDigit(16)
      if(d1 == null || d2 == null)
        throw ParseErr("Invalid char at " + (pos-1) + ": " + arg[pos-1..-1])
      
      Int decodedChar := d1.shiftl(4).or(d2)
      return [decodedChar, pos]
    }
    
    if (c == '+')
      return [' ', pos]
    
    return [c, pos]
  }
}
