using printf

mixin Validator {
  virtual Str[] validate(Obj? value) {
    return value != null ? validateNotNull(value) : [,]
  }
  virtual Str[] validateNotNull(Obj value) { return [,] }
}

const class Required: Validator {
  const Str message := "Specify a value"
  
  override Str[] validate(Obj? cleanedValue) {
    return cleanedValue == null ? [message] : [,]
  }
}

const class MinLength: Validator {
  const Int minLength
  const Str message := "Value shouldn’t be shorter than %s"
  new make(Int minLength, |This|? f := null) { this.minLength = minLength; f?.call(this) }
  
  override Str[] validateNotNull(Obj value) {
    return (value as Str).size() < minLength ? [Format.printf(message, [minLength])] : [,]
  }
}

const class MaxLength: Validator {
  const Int maxLength
  const Str message := "Value shouldn’t be longer than %s"
  new make(Int maxLength, |This|? f := null) { this.maxLength = maxLength; f?.call(this) }
  
  override Str[] validateNotNull(Obj value) {
    return (value as Str).size() > maxLength ? [Format.printf(message, [maxLength])] : [,]
  }
}

const class MinValue: Validator {
  const Obj minValue
  const Str message := "Value shouldn’t be lower than %s"
  new make(Obj minValue, |This|? f := null) { this.minValue = minValue; f?.call(this) }
  
  override Str[] validateNotNull(Obj value) {
    return value < minValue ? [Format.printf(message, [minValue])] : [,]
  }
}

const class MaxValue: Validator {
  const Obj maxValue
  const Str message := "Value shouldn’t be bigger than %s"
  new make(Obj maxValue, |This|? f := null) { this.maxValue = maxValue; f?.call(this) }
  
  override Str[] validateNotNull(Obj value) {
    return value > maxValue ? [Format.printf(message, [maxValue])] : [,]
  }
}

const class MatchesFunc: Validator {
  const |Obj->Str[]| func
  new make(|Obj->Str[]| func) { this.func = func }
  
  override Str[] validateNotNull(Obj value) { return func.call(value) }
}

const class MatchesRegex: Validator {
  const Regex regex
  const Str notMathedMsg
  new make(Regex regex, Str notMatchMsg) { this.regex = regex; this.notMathedMsg = notMatchMsg}
  
  override Str[] validateNotNull(Obj value) {
    return regex.matches(value) ? [,] : notMathedMsg
  }
}