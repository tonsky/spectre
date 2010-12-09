using printf

abstract class Field: SafeStrUtil {
  virtual Str unknownErrMsg := "Unknown error: %s"
  
  virtual Str name
  virtual Obj label // Str or SafeStr
  virtual Str? id { get { &id ?: name } }
  
  virtual Obj prefix := "" // Str or SafeStr
  virtual Obj suffix := "" // Str or SafeStr
  virtual [Str:Str] attrs := [:]
  
  virtual Obj[] errors := [,] // Str[] or SafeStr[]
  virtual Validator[] validators
  virtual Void validate(Obj? cleanedData) {}
  
  virtual Obj? data
  readonly Obj? cleanedData {
    get { 
      if (isBound && isValid)
        return &cleanedData;
      else if(!isValid)
        throw Err("Cannot access cleanedData in invalid form")
      else
        throw Err("Cannot access cleanedData in unbound form")
      }
  }
  
  virtual Bool isValid := false
  virtual Bool isBound := false
  
  virtual Obj? parseData(Obj dataMap) { return dataMap->get(name, null)?->trim }
  
  virtual Bool bind(Obj dataMap) {
    isBound = true
    data = parseData(dataMap)
    if (errors.isEmpty) {
      try {
        validators.each { errors.addAll(it.validate(data)) }
        validate(data)
        if (errors.isEmpty) {
          &cleanedData = data
          isValid = true
        }
      } catch(Err err) {
        errors.add(Format.printf(unknownErrMsg, ["$err.msg"]))
      }
    }
    return errors.isEmpty
  }
  
  abstract SafeStr renderHtml()
  virtual SafeStr renderLabel() { safe("<label for=\"${escape(id)}\">" + escape(label) + "</label>") }
  virtual SafeStr renderErrors() {
    safe(errors.isEmpty ? "" : "<ul class=\"errorlist\"><li>" + errors.map { escape(it) }.join("</li><li>") + "</li></ul>")
  } 
  
//  protected Str esc(Str? str) { str == null ? "" : Util.xmlEscape(str) }
  virtual SafeStr renderAttrs() { safe(attrs.isEmpty ? "" : " " + attrs.join(" ") |v,k| {escape(k) + "=\"" + escape(v) + "\""}) }
  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null) {
    this.name = name
    this.label = label
    this.validators = validators
    f?.call(this)
  }
}

mixin TextInputWidget: SafeStrUtil {
  abstract SafeStr renderAttrs()
  abstract Obj prefix()
  abstract Obj suffix()
  abstract Str name()

  SafeStr renderWidget(Obj? data, Str id, Str widget := "text") {
    safe(escape(prefix)
       + "<input type=\"$widget\" name=\"" + escape(name) + "\""
         + (data != null ? " value=\"" + escape(data) +"\"" : "")
         + renderAttrs()
         + " id=\"${escape(id)}\""
       + " />"
       + escape(suffix))
  }
}

class StrField: spectre::Field, TextInputWidget {
  override Obj? parseData(Obj dataMap) { Str? res := dataMap->get(name, null)?->trim; return res == "" ? null : res }
  override SafeStr renderHtml() { renderWidget(data, id) }
  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class PasswordField: spectre::StrField, TextInputWidget {
  override SafeStr renderHtml() { renderWidget("", id, "password") } // do not render back provided passwords
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class TextareaField: spectre::StrField {
  override SafeStr renderHtml() {
    safe(escape(prefix)
        + "<textarea name=\"${escape(name)}\""
          + renderAttrs()
          + " id=\"${escape(id)}\""
        + ">"
          + (data != null ? escape(data) : "")
        + "</textarea>"
        + escape(suffix))
  }
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class HiddenField: spectre::StrField {
  override SafeStr renderHtml() { renderWidget(data, id, "hidden") }
  new make(Str name, Validator[] validators := [,], |This|? f := null): super(name, "", validators, f) {}
}

class IntField: spectre::Field, TextInputWidget {
  virtual Obj parseErrMsg := "Provide integer value"
  virtual Str[] thousandSeparators := [" ", " ", ","] // TODO move to app settings

  virtual Obj? parse(Str value) {
    thousandSeparators.each { value = value.replace(it, "") }   
    return Int.fromStr(value)
  }
  
  virtual SafeStr parseErr(ParseErr err) { escape(parseErrMsg) }
  
  override Obj? parseData(Obj dataMap) {
    Str? rawData := dataMap->get(name, null)?->trim
    if (rawData == "" || rawData == null)
      return null
    try {
      return parse(rawData)
    } catch(ParseErr err) {
      errors.add(parseErr(err))
      return rawData
    }
  }
  override SafeStr renderHtml() { renderWidget(data?.toStr, id) }  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class FloatField: spectre::IntField {
  override Obj parseErrMsg := "Provide a float value with a ‘%s’ delimeter"
  override Str[] thousandSeparators := [" ", " "] // TODO move to app settings
  virtual Str[] parseFractionSep := [".", ","] // TODO move to app settings
  virtual Str printFractionSep := "."
  
  override Obj? parse(Str value) {
    thousandSeparators.each { value = value.replace(it, "") }
    parseFractionSep.each { value = value.replace(it, ".") }
    return Float.fromStr(value)
  }
  
  override SafeStr parseErr(ParseErr err) { SafeFormat.printf(parseErrMsg, [printFractionSep]) }
  
  override SafeStr renderHtml() { renderWidget(data?.toStr?.replace(".", printFractionSep), id) }  
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class DecimalField: spectre::FloatField {
  override Obj? parse(Str value) {
    thousandSeparators.each { value = value.replace(it, "") }
    parseFractionSep.each { value = value.replace(it, ".") }
    return Decimal.fromStr(value)
  }
  new make(Str name, Str? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class BoolField: spectre::Field {
  override Obj? parseData(Obj dataMap) { dataMap->get(name, null) != null ? true : false }
  override SafeStr renderLabel() { safe("") }
  override SafeStr renderHtml() {
    safe(escape(prefix)
      + "<label for=\"${escape(id)}\">"
      + "<input type=\"checkbox\" name=\"${escape(name)}\"" 
        + (data == true ? " checked=\"checked\"" : "") 
        + renderAttrs()
        + " id=\"${escape(id)}\""
      + " />"
      + escape(label)
      + "</label>"
      + escape(suffix))
  }
  
  new make(Str name, Obj? label, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class SelectField: spectre::Field {
  virtual Obj unknownKeyMsg := "Unknown option selected: %s"
  
  ** List of [val: Obj?, optional label: Str, optional key: Str] tuples.
  ** If you specify 'val' only, it’s allowed to not to wrap it in list.
  ** E.g.:
  **   [[1, "Male", "key_man"], [2, "Woman"], [3], 4]
  ** will be interpreted as:
  **   [[1, "Male", "key_man"], [2, "Woman", "2"], [3, "3", "3"], [4, "4", "4"]
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
  
  override Obj? parseData(Obj dataMap) {
    rawKey := dataMap->get(name, "")
    selectedChoice := choices.find { _key(it) == rawKey }
    if (selectedChoice != null)
      return _val(selectedChoice)
    
    errors.add(SafeFormat.printf(unknownKeyMsg, [rawKey]))
    return null
  }

  protected Str _selectedKey(Obj? data) {
    selected := choices.find { _val(it) == data }
    return _key(selected)
  }
  
  override SafeStr renderHtml() {
    selectedKey := _selectedKey(data)
    return safe(escape(prefix) 
              + "<select name=\"${escape(name)}\""
                 + renderAttrs()
                 + " id=\"${escape(id)}\""
              + ">"
                + choices.map { "<option value=\"${escape(_key(it))}\""
                                + (_key(it)==selectedKey ? " selected=\"selected\"" : "") + ">"
                                + escape(_label(it))
                                + "</option>" }.join("\n")
              + "</select>"
              + escape(suffix))
  }
  
  new make(Str name, Obj? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {
    this.choices = choices
  }
}

class SelectRadioField: spectre::SelectField {
  virtual Obj separator := safe("<br/>\n")
  
  override SafeStr renderHtml() {
    selectedKey := _selectedKey(data)
    return safe(escape(prefix) +
                choices.map { "<label><input type=\"radio\" name=\"${escape(name)}\" value=\"${escape(_key(it))}\""
                              + (_key(it)==selectedKey ? " checked=\"checked\"" : "") + renderAttrs() + ">"
                              + escape(_label(it))
                              + "</label>" }.join(escape(separator).toStr)
                + escape(suffix))
  }
  new make(Str name, Obj? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, choices, validators, f) {
    // There always should be one selected radiobutton
    if (choices.size > 0 && choices.find { _val(it) == data } == null)
      data = _val(choices[0])
  }
}

class MultiCheckboxField: spectre::SelectField {
  virtual Obj separator := safe("<br/>\n")
  
  override Obj? parseData(Obj dataMap) {
    Str[]? selectedKeys
    if (Util.supports(dataMap, "getList"))
      selectedKeys = dataMap->getList(name, null)
    else {
      selectedKeys = dataMap->get(name, null)
      if(selectedKeys != null)
        selectedKeys = _toList(selectedKeys)
    }
    
    if (selectedKeys == null)
      return [,]
    
    selectedKeys.each |k| {
      if (choices.all |ch| { _key(ch) != k })
        errors.add(Format.printf(unknownKeyMsg, [k]))
    }
    return choices.findAll { selectedKeys.contains(_key(it)) }.map {_val(it)}
  }

  protected Str[] _selectedKeys(Obj? data) {
    if (data == null)
      return [,]
    selected := choices.findAll { (data as Obj?[]).contains(_val(it)) }
    return selected.map { _key(it) }
  }
  
  override SafeStr renderLabel() { escape(label) }
  override SafeStr renderHtml() {
    selectedKeys := _selectedKeys(data)
    return safe(escape(prefix) 
              + choices.map { "<label><input type=\"checkbox\" name=\"${escape(name)}\" value=\"" + escape(_key(it)) + "\""
                              + (selectedKeys.contains(_key(it)) ? " checked=\"checked\"" : "") + renderAttrs() + ">"
                              + escape(_label(it))
                              + "</label>" }.join(escape(separator).toStr)
              + escape(suffix))
  }
  
  new make(Str name, Obj? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, choices, validators, f) {}
}

class MultiSelectField: MultiCheckboxField {
  override SafeStr renderLabel() { spectre::Field.super.renderLabel() }
  override SafeStr renderHtml() {
    selectedKeys := _selectedKeys(data)
    return safe(escape(prefix)
              + "<select name=\"${escape(name)}\" multiple=\"multiple\""
                + renderAttrs()
                + " id=\"${escape(id)}\""
              + ">"
                  + choices.map { "<option value=\"${escape(_key(it))}\""
                                   + (selectedKeys.contains(_key(it)) ? " selected=\"selected\"" : "") + ">"
                                   + escape(_label(it))
                                   + "</option>" }.join("\n")
              + "</select>"
              + escape(suffix))
  }
  
  new make(Str name, Obj? label, Obj[] choices, Validator[] validators := [,], |This|? f := null): super(name, label, choices, validators, f) {}
}

class DateField: spectre::Field, TextInputWidget {
  virtual Obj parseErrMsg := "Date is required in format ‘%s’"
  virtual Str[] parseFormats := ["D.M.YYYY", "M/D/YYYY", "YYYY-M-D"]
  virtual Str printFormat := "D.MM.YYYY" 
  
  override Obj? parseData(Obj dataMap) {
    rawData := dataMap->get(name, null)?->trim
    if (rawData == null || rawData == "")
      return null
    
    Date? parsed := parseFormats.eachWhile { Date.fromLocale(rawData, it, false) }
    if (parsed != null)
      return parsed
    
    errors.add(SafeFormat.printf(parseErrMsg, [printFormat]))
    return rawData
  }

  override SafeStr renderHtml() {
    if (data == null)
      data = ""
    else if (data is Date)
      data = (data as Date).toLocale(printFormat)
    return renderWidget(data, id)
  }
  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {
    attrs.getOrAdd("size") {"10"}
  }
}

class DateSelectField: spectre::Field {
  virtual Obj parseErrMsg := "Provide a correct date"
  virtual Str[][] monthes := Month.vals.map { [(it.ordinal+1).toStr, it.localeFull] }
  virtual Range years := 2001..Date.today.year+1
  
  override Obj? parseData(Obj dataMap) {
    d := dataMap->get(name+"[d]", "1")
    m := dataMap->get(name+"[m]", "0")
    y := dataMap->get(name+"[y]", "2001")
    
    Date? parsed := Date.fromLocale("${d}.${m}.${y}", "D.M.YYYY", false)
    if (parsed != null)
      return parsed
    
    errors.add(parseErrMsg)
    return [d, m, y]
  }
  
  override SafeStr renderLabel() { safe("<label for=\"${escape(id)}_d\">" + escape(label) + "</label>") }
  override SafeStr renderHtml() {
    Str? d
    Str? m
    Str? y
    if (data is Date) {
      d = (data as Date).day.toStr
      m = ((data as Date).month.ordinal+1).toStr
      y = (data as Date).year.toStr
    } else if (data is List) {
      d = (data as Str[])[0]
      m = (data as Str[])[1]
      y = (data as Str[])[2]
    }
    days := "<select name=\"$name[d]\""
        + renderAttrs()
        + " id=\"${escape(id)}_d\""
      + ">"
      + (1..31).map { "<option value=\"$it\"" + (it.toStr==d?" selected=\"selected\"":"") + ">$it</option>" }.join
      + "</select>"
    monthes := "<select name=\"$name[m]\""
        + renderAttrs()
        + " id=\"${escape(id)}_m\""
      + ">"
      + monthes.map { "<option value=\"${it[0]}\""+(it[0]==m?" selected=\"selected\"":"")+">${it[1]}</option>" }.join
      + "</select>"
    years := "<select name=\"$name[y]\""
        + renderAttrs()
        + " id=\"${escape(id)}_y\""
      + ">"
      + years.map { "<option value=\"$it\""+(it.toStr==y?" selected=\"selected\"":"")+">$it</option>" }.join
      + "</select>"
    return safe(escape(prefix) + days + monthes + years + escape(suffix))
  }
  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {}
}

class TimeField: spectre::Field, TextInputWidget {
  virtual Obj parseErrMsg := "Time is required in format ‘%s’"
  virtual Str[] parseFormats := ["k:m a", "k:m:SS a", "h:m", "h:m:SS"]
  virtual Str printFormat := "hh:mm"
  
  override Obj? parseData(Obj dataMap) {
    rawData := dataMap->get(name, null)?->trim
    if (rawData == null || rawData == "")
      return null
    
    normalized := (rawData as Str).lower
    Time? parsed := parseFormats.eachWhile { Time.fromLocale(normalized, it, false) }
    if (parsed != null)
      return parsed
    
    errors.add(SafeFormat.printf(parseErrMsg, [printFormat]))
    return rawData
  }

  override SafeStr renderHtml() {
    if (data == null)
      data = ""
    else if (data is Time)
      data = (data as Time).toLocale(printFormat)
    return renderWidget(data, id)
  }
  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {
    attrs.getOrAdd("size") {"3"}
  }
}

class DateTimeField: spectre::Field, TextInputWidget {
  virtual Obj parseErrMsg := "Time is required in format ‘%s’"
  virtual Str[] parseFormats :=  ["k:m a D.M.YYYY", "k:m aa D.M.YYYY", "h:m D.M.YYYY", "k:m a M/D/YYYY", "k:m aa M/D/YYYY", "h:m M/D/YYYY"]
  virtual Str printFormat := "hh:mm D.MM.YYYY"
  virtual TimeZone timezone := TimeZone.cur
  
  override Obj? parseData(Obj dataMap) {
    rawData := dataMap->get(name, null)?->trim
    if (rawData == null || rawData == "")
      return null
    
    normalized := (rawData as Str).lower
    DateTime? parsed := parseFormats.eachWhile { DateTime.fromLocale(normalized, it, timezone, false) }
    if (parsed != null)
      return parsed
    
    errors.add(SafeFormat.printf(parseErrMsg, [printFormat]))
    return rawData
  }

  override SafeStr renderHtml() {
    if (data == null)
      data = ""
    else if (data is DateTime)
      data = (data as DateTime).toTimeZone(timezone).toLocale(printFormat)
    return renderWidget(data, id)
  }
  
  new make(Str name, Obj? label := name, Validator[] validators := [,], |This|? f := null): super(name, label, validators, f) {
    attrs.getOrAdd("size") {"16"}
  }
}