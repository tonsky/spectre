**
** A map with support of multiple values for key, [Str:Str[]]
** 
class QueryMap {
  const static Log log := WatchPodActor#.pod.log
  
  internal [Str:Str[]] impl

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

  private new makeWith([Str:Str[]] impl) {
    this.impl = impl
  }

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
  Str? get(Str key, Str? _def := def) {
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
  Str[]? getList(Str key, Str[]? _def := defList) { impl.get(key, _def) }

  Bool containsKey(Str key) { impl.containsKey(key) }

  Str[] keys() { impl.keys }

  **
  ** Get a list of all the mapped values, using same last-value logic as get()
  ** for lists of values.
  ** >>> qm := QueryMap.make(["a": ["b", "c", "d"], "e": "f"])
  ** >>> qm.vals
  ** ["d", "f"]
  **
  Str[] vals() { impl.vals.map |Str[] v -> Str| { chooseVal(v) }  }

  **
  ** Get a list of all the mapped values as lists.
  ** >>> qm := QueryMap.make(["a": ["b", "c", "d"], "e": "f"])
  ** >>> qm.valsLists
  ** [["b", "c", "d"], ["f"]]
  **
  Str[][] valsLists() { impl.vals }
  
  **
  ** Get a list of all the mapped values as a flat list. 
  ** >>> qm := QueryMap.make(["a": ["b", "c", "d"], "e": "f"])
  ** >>> qm.valsListsFlat
  ** ["b", "c", "d", "f"]
  ** 
  Str[] valsListsFlat() { result := Str[,]; impl.vals.each { result.addAll(it) }; return result }
  
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
  ** already mapped, then throw the ArgErr.  Return this.  If key
  ** does not return true for Obj.isImmutable, then throw NotImmutableErr.
  ** If key is null throw NullErr.  Throw ReadonlyErr if readonly.
  **
  This add(Str key, Str val) { impl.add(key, Str[val]); return this }

  **
  ** Same as `add`, but maps list of values to a single key.
  ** 
  This addList(Str key, Str[] val) { impl.add(key, wrapToList(val)); return this }

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

  **
  ** The default value to use for `get` or `getList` when a key isn't mapped.
  ** For `getList` returns defList as default, for `get` returns defList[-1] (== def).  
  ** This field defaults to null.  The value of 'def' must be immutable
  ** or NotImmutableErr is thrown.  Getting this field is readonly safe.
  ** Throw ReadonlyErr if set when readonly.
  **
  Str[]? defList
  
  **
  ** An accessor to defList. Reading from this field returns defList[-1]
  ** (a default value for `get`). Writing to this field overwrites defList to [def]
  **
  Str? def { get {chooseVal(defList)} set { defList = (it == null ? null : Str[it].toImmutable)} }

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
  
//////////////////////////////////////////////////////////////////////////
// URI
//////////////////////////////////////////////////////////////////////////
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
    map := QueryMap.make
    if (q == null)
      return map

    try {
      start := 0
      eq := 0
      len := q.size
      prev := 0
      escaped := false
      
      for (i := 0; i < len; ++i) {
        ch := q[i]
        if (prev != '\\') {
          if (ch == '=') eq = i
          if (ch != '&' && ch != ';') {
            prev = ch
            continue
          }
        } else {
          escaped = true
          prev = (ch != '\\') ? ch : 0
          continue
        }

        if (start < i) {
          addQueryParam(map, q, start, eq, i, escaped)
          escaped = false
        }

        start = eq = i+1
      }

      if (start < len)
        addQueryParam(map, q, start, eq, len, escaped)
    } catch (Err e) {
      // don't let internal error bring down whole uri
      log.err("Error parsing uri", e) 
    }

    return map
  }
  
  private static Void addQueryParam(QueryMap map, Str q, Int start, Int eq, Int end, Bool escaped) {
    Str? key
    Str? val
    if (start == eq && q[start] != '=') {
      key = toQueryStr(q, start, end, escaped)
      val = ""
    } else {
      key = toQueryStr(q, start, eq, escaped)
      val = toQueryStr(q, eq+1, end, escaped)
    }

    map.setList(key, map.getList(key, Str?[,]).add(val))
  }
  
  private static Str toQueryStr(Str q, Int start, Int end, Bool escaped) {
    if (!escaped)
      return q[start..<end]
    s := StrBuf.make(end-start)
    prev := 0
    for (i := start; i < end; ++i) {
      Int c := q[i]
      if (c != '\\') {
        s.addChar(c)
        prev = c
      } else {
        if (prev == '\\') {
          s.addChar(c)
          prev = 0
        } else
          prev = c
      }
    }
    return s.toStr
  }

}
