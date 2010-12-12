**
** Forms are Spetre’s approach to handling user-submitted forms.
** Forms are resropsible for:
** 
** * Rendering HTML with automatically generated widgets and basic layouts;
** * Converting submitted data to corresponding Fantom types;
** * Checking subbmited data against a set of validation rules;
** * Rendering form with error messages back to user if validation fails.
** 
** To define a form, create a class extending `Form` and define form fields
** as regular class fields.
** 
**   class MyForm : Form {
**     spectre::Field name := StrField("name", "Your name", [Required()])
**     spectre::Field bio := TextareaField("bio", "About yourself")
**   }
** 
** New form is considered _unbound_ and can be displayed only. To populate form
** with data, call `bind` method with `Map` or `QueryMap` of data. Submitted data
** will be converted and validated, form will became _bound_ and either _valid_ 
** (all validation passed) or _invalid_.
** 
**   myForm := MyForm() //unbound
**   if (myForm.bind(["name": "Ilya", "bio": "Have layed for 33 years"])) {
**     // bound valid
**     processForm(myForm.cleanedData)
**   } else {
**     // bound invalid
**     // rendering back with all the error messages  
**     return TemplateRes("page.html", ["form": myForm.asTable])
**   }
**   // rendering unbound form (initial)
**   return TemplateRes("page.html", ["form": myForm.asTable]) // bound invalid
** 
class Form: SafeStrUtil {
  **
  ** Lists of errors (`Str` or `SafeStr`) that don't belong to any particular field.
  ** It's recommeneded to populate this list in `validate`.
  ** 
  virtual Obj[] errors := [,]

  **
  ** Override this method to do validation of form in common, on set of fields,
  ** not of any particular field. Errors found should be stored in `errors`. This
  ** method will only be called if form has no field-specific errors. 
  ** 
  virtual Void validate() {}

  **
  ** Bind this form with data and validate it. This method moves form from _unbound_
  ** to _bound_ state.
  **   
  virtual Bool bind(Obj dataMap) {
    if (!fields.map { it.bind(dataMap) }.all { it })
      return false
    validate
    return errors.isEmpty
  }
  
  **
  ** Check if bound form has any errors, either form- or field-level.
  ** 
  virtual Bool isValid() { errors.isEmpty && fields.all { it.isValid } }

  **
  ** All bound fields’ data as '[Str:Obj?]' array, converted to appropriate types
  ** and validated.
  ** 
  virtual [Str:Obj?] cleanedData() {
    !isValid() ? throw Err("Cannot access cleanedData in invalid form") : 
    Str:spectre::Field[:].addList(fields) |f| { f.name }.map { it.cleanedData }
  }  

  
  **
  ** Define 'Str[] exclude' field in form class if you need to exclude class-level
  ** Field slots from form's fields.
  ** 
  protected virtual Str[]? exclude() { null }

  **
  ** Define 'Str[] include' field in form class if you need to specify implicitly
  ** which class-level Field slots should became form's fields.
  ** 
  protected virtual Str[]? include() { null }
  
  **
  ** List of active form’s fields. To manage fields’ list dynamically, 
  ** override this method.
  ** 
  protected virtual spectre::Field[] fields() {
    this.typeof.fields.findAll { it.type.fits(spectre::Field#) && isIncluded(it.name) }.map { it.get(this) }
  }
  
  **
  ** This method is used to identify whether field should be included to form or not.
  ** 
  protected virtual Bool isIncluded(Str name) {
    include != null ? include.contains(name) : true &&  
    (exclude != null ? !exclude.contains(name) : true)
  }
  
  **
  ** Render form as a list of 
  **   <tr>
  **     <th> {field’s label} </th>
  **     <td> {field errors} {field} </td>
  **   </tr>
  ** 
  ** with form’s errors as first row.
  ** 
  virtual SafeStr asTable() {
    safe(
      (errors.isEmpty ? "" : "<tr class=\"form_errorrow\"><td colspan=\"2\">${renderErrors}</td></tr>")
      + fields.map {
        "<tr" + (it.isBound && !it.isValid ? " class=\"errorrow\"" : "") + "><th>"
          + it.renderLabel
        + "</th><td>"
          + it.renderErrors
          + it.renderHtml
        + "</td></tr>"
      }.join
    )
  }
  
  **
  ** Render form’s errors list as 
  **   <ul class="errorlist">
  **     <li> {error} </li>
  **     ...
  **   </ul>
  ** 
  virtual SafeStr renderErrors() {
    safe(errors.isEmpty ? "" : "<ul class=\"errorlist\"><li>" + errors.map { escape(it) }.join("</li><li>") + "</li></ul>")
  }
}