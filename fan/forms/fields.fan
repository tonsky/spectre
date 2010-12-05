using printf

abstract class Field {
  virtual Str name
  virtual Str label
  virtual Obj? initialData
  virtual Obj? nullValue := null
  
  virtual Str[] errors := [,]
  virtual Validator[] validators
  virtual Void validate(Obj? cleanedData) {}
  
  virtual Bool isBound := false
  virtual Obj? rawData
  readonly Obj? cleanedData { get { isBound ? &cleanedData : throw Err("Cannot access 'cleanedData' on unbound field") } }
  
  virtual Str unknownErrMsg := "Unknown error: %s"
  
  virtual Obj? dataToRaw(Obj dataMap) { return dataMap->get(name, null)?->trim }
  abstract Obj? rawToCleaned(Obj rawData)
  abstract Obj? cleanedToRaw(Obj? cleanedData)
  abstract Str rawToHtml(Str name, Obj? rawData)
  
  virtual Void bind(Obj dataMap) { isBound = true; rawData = dataToRaw(dataMap) }
  
  virtual Bool clean() {
    try {
      cleanedData := (rawData == null || rawData == "") ? nullValue : rawToCleaned(rawData)
      validators.each { errors.addAll(it.validate(cleanedData)) }
      validate(cleanedData)
      if (isValid)
        this.&cleanedData = cleanedData        
    } catch(Err err) {
      errors.add(Format.printf(unknownErrMsg, ["$err.msg"]))
    }
    return isValid
  }
  
  virtual Str renderHtml() {
    dataToRender := !isBound ? cleanedToRaw(initialData) :
      (isValid ? cleanedToRaw(cleanedData) : rawData)
    return rawToHtml(name, dataToRender)
  }

  virtual Str renderErrors() {
    return errors.isEmpty ? "" : 
      """<ul class="errorlist"><li>""" + errors.join("</li><li>") + """</li></ul>"""
  }
  
  virtual Bool isValid() { errors.isEmpty } 
  
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null) {
    this.name = name
    this.label = label
    this.validators = validators
    f?.call(this)
  }
}

mixin TextInputWidget {
  Str rawToHtml(Str name, Obj? rawData) {
    """<input type="text" name="$name" """ + (rawData != null ? """value="$rawData" """ : "") + "/>"
  }
}

class StrField: spectre::Field, TextInputWidget {
  override Obj? rawToCleaned(Obj rawData) { rawData as Str }
  override Obj? cleanedToRaw(Obj? cleanedData) { cleanedData as Str }
  
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class IntField: spectre::Field, TextInputWidget {
  virtual Str parseErrMsg := "Provide integer value"
  
  override Obj? rawToCleaned(Obj rawData) {
    try {
      return Int.fromStr(rawData)
    } catch(ParseErr err) {
      errors.add(parseErrMsg)
      return null
    }
  }
  override Obj? cleanedToRaw(Obj? cleanedData) { cleanedData?.toStr }
  
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class BoolField: spectre::Field {
  override Obj? dataToRaw(Obj dataMap) { dataMap->get(name, null) != null ? "true" : "false" }
  override Obj? rawToCleaned(Obj rawData) { Bool.fromStr(rawData) }
  override Obj? cleanedToRaw(Obj? cleanedData) { cleanedData == null ? "false" : cleanedData.toStr }

  override Str rawToHtml(Str name, Obj? rawData) {
    """<label><input type="checkbox" name="$name" """ + (rawData == "true" ? "checked=\"checked\"" : "") + "/></label>"
  }
  
  new make(Str name, Str? label, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}


class SelectField: spectre::Field {
  ** List of [val: Obj?, optional label: Str, optional key: Str] tuples
  ** If you specify 'val' only, it is allowed to not to wrap it in list
  Obj[] choices
  
  protected Obj?[] _toList(Obj tuple) { tuple is List ? tuple : [tuple] }
  protected Obj? _val(Obj? tuple) {
    if (tuple == null)
      return null
    return _toList(tuple)[0]
  }

  protected Str _label(Obj? _tuple) {
    if (_tuple == null)
      return ""
    tuple := _toList(_tuple)
    return tuple.size > 1 ? tuple[1] : (tuple[0] == null ? "" : tuple[0].toStr)    
  }
  
  protected Str _key(Obj? _tuple) {
    if (_tuple == null)
      return ""
    tuple := _toList(_tuple)
    return tuple.size > 2 ? tuple[2] : (tuple[0] == null ? "" : tuple[0].toStr)
  }
  
  override Obj? rawToCleaned(Obj rawData) { _val(choices.find { _key(it) == rawData }) }
  override Obj? cleanedToRaw(Obj? cleanedData) { _key(choices.find { _val(it) == cleanedData }) }

  override Str rawToHtml(Str name, Obj? rawData) {
    "<select name=\"$name\">"
    + choices.map { "<option value=\"" + _key(it) + "\""
                    + (_key(it)==rawData ? " selected=\"selected\"" : "") + ">"
                    + _label(it)
                    + "</option>" }.join("\n")
    + "</select>"
  }
  
  new make(Str name, Str? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {
    this.choices = choices
  }
}

class SelectRadioField: spectre::SelectField {
  override Str rawToHtml(Str name, Obj? rawData) {
    choices.map { "<label><input type=\"radio\" name=\"$name\" value=\"" + _key(it) + "\""
                    + (_key(it)==rawData ? " checked=\"checked\"" : "") + ">"
                    + _label(it)
                    + "</label>" }.join("<br/>\n")
  }
  new make(Str name, Str? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, choices, validators, f) {
    if (choices.size > 0 && choices.find { _val(it) == initialData } == null)
      initialData = _val(choices[0])
  }
}

class MultiCheckboxField: spectre::SelectField {
  override Obj? nullValue := [,] 
  
  override Obj? dataToRaw(Obj dataMap) {
    if (Util.supports(dataMap, "getList"))
      return dataMap->getList(name, null)
    
    data := dataMap->get(name, null)
    return _toList(data)    
  }
  
  override Obj? rawToCleaned(Obj rawData) { choices.findAll { (rawData as List).contains(_key(it)) }.map {_val(it)} }
  override Obj? cleanedToRaw(Obj? cleanedData) { choices.findAll { cleanedData == null ? false : (cleanedData as List).contains(_val(it)) }.map { _key(it) } }

  override Str rawToHtml(Str name, Obj? rawData) {
    choices.map { "<label><input type=\"checkbox\" name=\"$name\" value=\"" + _key(it) + "\""
                    + ((rawData as List).contains(_key(it)) ? " checked=\"checked\"" : "") + ">"
                    + _label(it)
                    + "</label>" }.join("<br/>\n")
  }
  
  new make(Str name, Str? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, choices, validators, f) {
    initialData = initialData == null ? null : _toList(initialData)
  }
}

class MultiSelectField: MultiCheckboxField {
  override Str rawToHtml(Str name, Obj? rawData) {
    "<select name=\"$name\" multiple=\"multiple\">"
    + choices.map { "<option value=\"" + _key(it) + "\""
                    + ((rawData as List).contains(_key(it)) ? " selected=\"selected\"" : "") + ">"
                    + _label(it)
                    + "</option>" }.join("\n")
    + "</select>"
  }
  
  new make(Str name, Str? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, choices, validators, f) {}
}

class DateField: spectre::Field, TextInputWidget {
  virtual Str parseErrMsg := "Date is required in format \"%s\""
  virtual Str[] parseFormats := ["D.M.YYYY", "M/D/YYYY", "YYYY-M-D"]
  virtual Str printFormat { get { parseFormats[0] } set { parseFormats.insert(0, it) } } 
  
  override Obj? rawToCleaned(Obj rawData) {
    Date? parsed := parseFormats.eachWhile { Date.fromLocale(rawData, it, false) }
    if (parsed == null)
      errors.add(Format.printf(parseErrMsg, [printFormat]))
    return parsed    
  }

  override Obj? cleanedToRaw(Obj? cleanedData) {
    return cleanedData == null ? "" : (cleanedData as Date).toLocale(printFormat)
  }
  
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class DateSelectField: spectre::Field {
  virtual Str parseErrMsg := "Provide a correct date"
  virtual Str[][] monthes := Month.vals.map { [(it.ordinal+1).toStr, it.localeFull] }//(1..12).map { [it.toStr, Date.fromIso("2010-" + it.toStr.padl(2,'0') + "-01").toLocale("MMMM")] }
  virtual Range years := 2001..Date.today.year+1
  
  override Obj? dataToRaw(Obj dataMap) {
    [dataMap->get(name+"[d]", "1"),
     dataMap->get(name+"[m]", "0"),
     dataMap->get(name+"[y]", "2001")]    
  }
  
  override Obj? rawToCleaned(Obj rawData) {
    d := (rawData as Str[])[0]
    m := (rawData as Str[])[1]
    y := (rawData as Str[])[2]
    
    Date? parsed := Date.fromLocale("${d}.${m}.${y}", "D.M.YYYY", false)
    if (parsed == null)
      errors.add(parseErrMsg)
    return parsed    
  }

  override Obj? cleanedToRaw(Obj? cleanedData) {
    if (cleanedData == null)
      return ["1", "0", "2001"]
    d := cleanedData as Date
    return ["$d.day", (d.month.ordinal+1).toStr, "$d.year"]
  }
  
  override Str rawToHtml(Str name, Obj? rawData) {
    d := (rawData as Str[])[0]
    m := (rawData as Str[])[1]
    y := (rawData as Str[])[2]
    days := "<select name=\"$name[d]\">"+(1..31).map { "<option value=\"$it\"" + (it.toStr==d?" selected=\"selected\"":"") + ">$it</option>" }.join+"</select>"
    monthes := "<select name=\"$name[m]\">"+monthes.map { "<option value=\"${it[0]}\""+(it[0]==m?" selected=\"selected\"":"")+">${it[1]}</option>" }.join+"</select>"
    years := "<select name=\"$name[y]\">"+years.map { "<option value=\"$it\""+(it.toStr==y?" selected=\"selected\"":"")+">$it</option>" }.join+"</select>"
    return days + monthes + years
  }
  
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}