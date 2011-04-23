using spectre

class FormsApp : Router {
  new make() : super() {
    add(["/forms/", FormsViews#index])
  }
}

enum class Film {
  Matrix,
  LoTR,
  StarWars,
  IndianaJones
}

enum class Genders {
  Male, Female
}

class SampleForm : Form, SafeStrUtil {
  StrField nameF := StrField("name", safe("Str required<span style=\"color: red\">*</span>"), [Required()])
  PasswordField passwd := PasswordField("passwd", "Passwd") {}
  PasswordField passwd2 := PasswordField("passwd2", "Passwd repeated") {}
  TextareaField textarea := TextareaField("text", "Textarea (no “!” allowed)", 
    [MatchesFunc{(it as Str).contains("!") ? ["Should not contain “!”"] : [,]}]) {
    attrs = ["cols": "25", "rows": "5"]
  }
  IntField age := IntField("age", "Int, initial=18") { data = 18; attrs = ["id": "age", "size": "3"] }
  DecimalField decimal := DecimalField("body_temp", "Decimal, 0..100", [MinValue(0.0), MaxValue(100.0)]) {
    data = 36.6
    printFractionSep = ","
    attrs = ["size": "3"]
    suffix = safe("&deg;C")
  }
  DateField birthDate := DateField("birthdate", "Date YYYY/M/D") { data = Date.fromIso("1949-12-31"); printFormat = "M/D/YYYY" }
  DateSelectField birthDate2 := DateSelectField("birthdate2", "Date selects") {}
  TimeField now := TimeField("now", "Time") { data = Time.now }
  DateTimeField dt := DateTimeField("dt", "DateTime") { data = DateTime.now }
  
  BoolField bool := BoolField("bool", "Checkbox, initial=true") { data = true }
  SelectField select := SelectField("select", "Select with custom keys", ["Male", "Female", [null, "-- Select --"]]) {}
  SelectRadioField select2 := SelectRadioField("select2", "Radio with custom keys", 
    [[Genders.Male, "Male (man)", "man"], [Genders.Female, "Female (woman)", "woman"], [null, "-- Select --"]]) { data = Genders.Female; separator = "\n" }

  Obj?[] films := [Film.Matrix, Film.LoTR, Film.StarWars, Film.IndianaJones]
  Obj?[] popular := [Film.Matrix, Film.LoTR]
  MultiCheckboxField multi2 := MultiCheckboxField("multi", "Multi checkbox w/ initial", films) { data = popular }
  MultiSelectField multi4 := MultiSelectField("multi2", "Multiselect w/ initial", films) { data = popular }
  
  override Void validate() {
    if(passwd.cleanedData != passwd2.cleanedData) {
      errors.add("Password and repeat doesn't match")
      passwd.isValid = false
      passwd.errors.add("Fix this")
      passwd2.isValid = false
      passwd2.errors.add("Fix this")
    }
  }
  
  override once spectre::Field[] fields() {
    dynFields := [1,2,3].map { StrField("field$it", "at least $it char", [Required(), MinLength(it)]) }
    return super.fields.dup.addAll(dynFields)
  }
}

class FormsViews {
  
  virtual Res index(Req req) {
    form := SampleForm()
    
    message := "Unbound form"
    messageClass := "info"
    
    if (req.method == "POST") {
      isValid := form.bind(req.post)
      
      message = "Bound invalid form"
      messageClass = "warn"
      
      if (isValid) {
        message = "Valid form\n\n" + form.cleanedData.join("\n")
        messageClass = "info"
      }
    }
    
    return TemplateRes("forms/index.html", 
      ["form": form.asTable,
       "message": message,
       "message_class": messageClass])
  }
}