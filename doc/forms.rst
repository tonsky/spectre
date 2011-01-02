=======
 Forms
=======

Forms are Spetre’s approach to handling user-submitted forms. Forms are resropsible for:

* rendering HTML with automatically generated widgets and basic layouts;
* converting submitted data to corresponding Fantom types;
* checking subbmited data against a set of validation rules;
* rendering form with error messages back to user if validation fails.

To define a form, create a class extending :class:`Form` and define form fields
as regular class fields::

  class MyForm : Form {
    StrField name := StrField("name", "Your name", [Required()])
    TextareaField bio := TextareaField("bio", "About yourself")
    BoolField hasSuperpowers := BoolField("has_superpowers", "Has superpowers")
  }
 
New form is considered *unbound* and can be displayed only. To populate form
with data, call :func:`~Form.bind` method with :class:`Map` or :class:`QueryMap` of data. Submitted data will be converted and validated, form will became *bound* and either *valid* (all validation passed) or *invalid*::

  // creating unbound form:
  myForm := MyForm()
  
  // rendering unbound form (initial):
  return TemplateRes("page.html", ["form": myForm.asTable])
  
  // binding form against data:
  if (myForm.bind(["name": "Ilya", "bio": "Have layed for 33 years"])) {

    // form is now bound valid

    processForm(myForm.cleanedData)
    return ResRedirect("...")
  
  } else {

    // validation has failed, form is bound invalid
    // rendering back with all the error messages  
    
    return TemplateRes("page.html", ["form": myForm.asTable])
  }

Accessing form data
-------------------

After successful :func:`~Form.bind`, all form data is converted to corresponded Fantom types and is accessible through :attr:`Form.cleanedData` (referenced by fields’ names, not slot names) or ``Form.<field_slot>.cleanedData``::

  myForm.cleanedData["name"] // "Ilya"
  myForm.name.cleanedData // "Ilya"
  myForm.cleanedData["has_superpowers"] // false
  myForm.hasSuperpowers.cleanedData // false
  
If form is either *invalid* or *unbound*, accessing :attr:`Form.cleanedData` will raise :class:`Err`. To check if form is valid or not, check :func:`Form.bind` return value or use :func:`Form.isValid`.

Form fields
-----------

:class:`Field` is a part of :class:`Form` representing single value requested from user. 

It is also possible to use single :class:`Field` on its own. :class:`Field`s have same bound/unbound valid/invalid states as :class:`Form`s, :attr:`~Field.cleanedData`, :attr:`~Field.errrors` and so on.

Rendering form and fields
-------------------------

:class:`Form` can be rendered with :func:`~Form.asTable` method. It will return :class:`SafeStr` html snippet with fields’ labels, widgets in their current state and error messages, wrapped with ``<tr><th></th><td></td></tr>``. It won’t contain ``table`` tag, you should write it by yourself.::

  >>> myForm.asTable
  
  <tr>
    <th>
      <label for="name">Your name</label>
    </th>
    <td>
      <input type="text" name="name" id="name" value="Ilya"/>
    </td>
  </tr>
  
  <tr>
    <th>
      <label for="bio">About yourself</label>
    </th>
    <td>
      <textarea name="bio" id="bio">Have layed for 33 years</textarea>
    </td>
  </tr>
  
  <tr>
    <th></th>
    <td>
      <label for="has_superpowers">
        <input type="checkbox" name="has_superpowers" id="has_superpowers" />
        Has superpowers
      </label>
    </td>
  </tr> 

Individual fields can be rendered on more detailed level::

  >>> myForm.name.renderWidget
  
  <input type="text" name="name" id="name" value="Ilya"/>
  
  >>> myForm.name.renderLabel
  
  <label for="name">Your name</label>
  
  >>> myForm.name.renderErrors
  
  <ul class="errorlist"><li>Specify a value</li></ul>

Validating form
---------------

Form validation consist of three steps:

1. converting raw data to Fantom types in fields;
2. running fields validators;
3. running form validtaion.

All errors occured on these steps are stored in :attr:`Field.errors` (1, 2) and :attr:`Form.errors` (3) slots. If there is at least one error, form became invalid and its :attr:`Form.cleanedData` cannot be accessed.

Field’s validators can be passed to field’s constructor::

  StrField name := StrField("name", "Your name", [Required(), MinLength(10), MaxLength(25)])  

There are a bunch of field validators built-in with Spectre: :class:`Required`, :class:`MinLength`, :class:`MaxLength`, :class:`MinValue`, :class:`MaxValue`, :class:`MatchesRegex` and :class:`MatchesFunc`.

All errors found during individual field’s validation are stored in :attr:`Field.errors` slot.

When fields validation isn’t enough, or you have conditions involving more than one field, you redefine :func:`Form.validate` method (3) and store results of your validation in :attr:`Form.errors` slot as plain :class:`Str` or :class:`SafeStr`.::

  class MyForm : Form {
    StrField name := StrField("name", "Your name")
    TextareaField bio := TextareaField("bio", "About yourself")
    BoolField hasSuperpowers := BoolField("has_superpowers", "Has superpowers")
  
    override Void validate() {
      if ((cleanedData["name"] as Str)?.size > (cleanedData["bio"] as Str)?.size)
        errors.add("Bio is supposed to be more detailed than name")
    }
  }

:func:`Form.validate` method will only be invoked if form has no field-specific errors (1, 2).

List of build-in fields
-----------------------

.. class:: StrField

   ``<input type="text">`` field which will be converted to :class:`Str` object.


.. class:: PasswordField

   ``<input type="password">`` field which will be converted to :class:`Str` object.

   
.. class:: TextareaField

   ``<textarea>`` field which will be converted to :class:`Str` object.


.. class:: HiddenField

   ``<input type="hidden">`` field which will be converted to :class:`Str` object.


.. class:: IntField
   
   ``<input type="text">`` field which will be converted to :class:`Int` object.


.. class:: DecimalField

   ``<input type="text">`` field which will be converted to :class:`Decimal` object.


.. class:: FloatField

   ``<input type="text">`` field which will be converted to :class:`Float` object. See :class:`DecimalField`.


.. class:: BoolField

   ``<input type="checkbox">`` field which will be converted to :class:`Bool` object.


.. class:: SelectField
   
   ``<select>`` field which will be converted to one of provided ``choices``.


.. class:: SelectRadioField

   :class:`SelectField` rendered as a set of radiobuttons.


.. class:: MultiCheckboxField

   Multiselect field which will be converted to a list of provided ``choices``. Will be rendered as a set of checkboxes.


.. class:: MultiSelectField
   
   Multiselect field which will be converted to a list of provided ``choices``. Will be rendered as a ``<select multiple="multiple">``. See :class:`MultiCheckboxField`.


.. class:: DateField

   ``<input type="text">`` field which will be converted to a :class:`Date`.


.. class:: TimeField
   
   ``<input type="text">`` field which will be converted to a :class:`Time`.


.. class:: DateTimeField
   
   ``<input type="text">`` field which will be converted to a :class:`DateTime`.


.. class:: DateSelectField

   :class:`Date` field rendered as three ``<select>`` lists: day, month, year. This is also an example of a single field having more than one widget.


Advanced techniques
-------------------

By default, all :class:`Form` slots which extend :class:`Field` are included to form. If you need to specify, which fields to exclude from form rendering/processing, or enumerate which to include, please override ``Str[]?`` :attr:`Form.exclude` and :attr:`Form.include` slots.

If you need to generate fields list dynamically, override :func:`Form.fields` method. It should return list of :class:`spectre::Field` instances that form will contain::

  class DynForm : Form {
    ... // usual fields’ definitions
  
    override once spectre::Field[] fields() {
      dynFields := ...
      return super.fields.dup.addAll(dynFields)
    }
  }
  
:func:`Form.fields` will be called several times during form processing, so you should specify ``once`` modifier on it or ensure otherways that it returns same field *instances* each time it is called.

