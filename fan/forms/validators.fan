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

const class MaxLength: Validator {
  const Int maxLength
  const Str message := "Value should be no longer than %s"
  new make(Int maxLength, |This|? f := null) { this.maxLength = maxLength; f?.call(this) }
  
  override Str[] validateNotNull(Obj value) {
    return (value as Str).size() > maxLength ? [Format.printf(message, [maxLength])] : [,]
  }
}

const class MinLength: Validator {
  const Int minLength
  const Str message := "Value should be no shorter than %s"
  new make(Int minLength, |This|? f := null) { this.minLength = minLength; f?.call(this) }
  
  override Str[] validateNotNull(Obj value) {
    return (value as Str).size() < minLength ? [Format.printf(message, [minLength])] : [,]
  }
}
