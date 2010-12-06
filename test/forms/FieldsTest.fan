
mixin FieldTestMixin {
  abstract Void verify(Bool cond, Str? msg := null)
  abstract Void verifyEq(Obj? o1, Obj? o2, Str? msg := null)
  
  Void verifyField(spectre::Field f, [Str:Obj?] data, Bool isValid, Obj? cleanedVal) {
    verifyEq(f.bind(data), isValid)
    verifyEq(f.isValid, isValid)
    verify(f.errors.isEmpty == isValid, "$f.errors")
    if (f.isValid)
      verifyEq(f.cleanedData, cleanedVal)
  }
  
  Void verifyInputField(spectre::Field f, [Str:Str] data, Bool isValid, Obj? cleanedVal, Str? renderedVal) {
    verifyField(f, data, isValid, cleanedVal)
    if(renderedVal == null)
      verify(!f.renderHtml.contains("value=\""), f.renderHtml)
    else
      verify(f.renderHtml.contains("value=\"$renderedVal\""), f.renderHtml)
  }
}

class FieldsTest: Test, FieldTestMixin {
  Void testBasicLogic() {
    // basic logic
    verifyInputField(StrField("name"), ["x": "y", "name": "val", "z": "t"],
                true, "val", "val")
    
    verifyInputField(StrField("name"), ["x": "y", "name": "", "z": "t"],
                true, null, null)
    
    verifyInputField(StrField("name"), ["x": "y", "z": "t"],
                true, null, null)
    
    verifyInputField(IntField("name"), ["x": "y", "name": "", "z": "t"],
                true, null, null)
    
    // incorrect value
    verifyInputField(IntField("name"), ["x": "y", "name": "val", "z": "t"],
                false, null, "val") // "val" should be rendered back
  }
  
  Void testInitialsLogic() {
    // initial
    f := IntField("name") { data=25 }
    verify(f.renderHtml.contains("value=\"25\""), f.renderHtml)

    verifyInputField(f, ["x": "y", "name": "21", "z": "t"],
                true, 21, "21")
    
    verifyInputField(IntField("name") { data=25 }, ["x": "y", "name": "val", "z": "t"],
                false, null, "val") // "val" should be rendered back

    verifyInputField(IntField("name") { data=25 }, ["x": "y", "z": "t"],
                true, null, null) // shouldn't render value
  }
  
  Void testValidationLogic() {
    // validations
    verifyInputField(StrField("name", "label", [Required()]), ["x": "y", "name": "val", "z": "t"],
                true, "val", "val")

    verifyInputField(StrField("name", "label", [Required()]), ["x": "y", "z": "t"],
                false, null, null)
    
    verifyInputField(StrField("name", "label", [Required()]), ["x": "y", "name": "", "z": "t"],
                false, null, null)
    
    verifyInputField(StrField("name", "label", [Required()]) { data = "in" }, ["x": "y", "z": "t"],
                false, null, null)
  }

  
  Void testIntField() {
    verifyInputField(IntField("f", "label"), ["f": "12"],  true,  12,   "12")
    verifyInputField(IntField("f", "label"), ["f": "  1 200 "], true, 1200, "1200")
    verifyInputField(IntField("f", "label"), ["f": ""],    true,  null, null)
    verifyInputField(IntField("f", "label"), [:],          true,  null, null)
    verifyInputField(IntField("f", "label"), ["f": "abc"], false, null, "abc")
    
    verifyInputField(IntField("f", "label", [Required()]), ["f": "12"],  true,  12,   "12")
    verifyInputField(IntField("f", "label", [Required()]), ["f": ""],    false, null, null)
    verifyInputField(IntField("f", "label", [Required()]), [:],          false, null, null)
    verifyInputField(IntField("f", "label", [Required()]), ["f": "abc"], false, null, "abc")
  }

  Void testFloatField() {
    verifyInputField(FloatField("f", "label"), ["f": ""], true, null, null)
    verifyInputField(FloatField("f", "label"), ["f": "1 200"], true, 1200.0f,   "1200.0")
    verifyInputField(FloatField("f", "label"), ["f": " - 1 200,776 "], true, -1200.776f, "-1200.776")
    verifyInputField(FloatField("f", "label"), ["f": "1-200"], false, null, "1-200")
  }
  
  Void testDecimalField() {
    verifyInputField(DecimalField("f", "label"), ["f": ""], true, null, null)
    verifyInputField(DecimalField("f", "label"), ["f": "1 200"], true, Decimal.fromStr("1200"),   "1200")
    verifyInputField(DecimalField("f", "label"), ["f": " - 1 200,776 "], true, -1200.776, "-1200.776")
    verifyInputField(DecimalField("f", "label"), ["f": "1-200"], false, null, "1-200")
  }
  
  Void verifyCheckedField(spectre::Field f, [Str:Str] data, Bool isValid, Obj? cleanedVal, Bool checked) {
    verifyField(f, data, isValid, cleanedVal)
    verify(f.renderHtml.contains("checked=\"checked\"") == checked, f.renderHtml)
  }

  
  Void testBoolField() {
    verifyCheckedField(BoolField("f", "label"), ["f": "true"],  true, true, true)
    verifyCheckedField(BoolField("f", "label"), ["f": "false"], true, true, true)
    verifyCheckedField(BoolField("f", "label"), [:],            true, false, false)
    verifyCheckedField(BoolField("f", "label"), ["f": ""],      true, true, true)
    verifyCheckedField(BoolField("f", "label"), ["f": "abc"],   true, true, true)
  }

  Void verifySelectField(spectre::Field f, [Str:Str] data, Bool isValid, Obj? cleanedVal, Str? selectedKey) {
    verifyField(f, data, isValid, cleanedVal)
    if(selectedKey != null)
      verify(f.renderHtml.contains("<option value=\"$selectedKey\" selected=\"selected\""), f.renderHtml)
    else
      verify(!f.renderHtml.contains("selected=\"selected\""), f.renderHtml)
  }
  
  Void testSelectField() {
    Obj[] list1 := [1, 2, 3]
    verifySelectField(SelectField("f", "label", list1), ["f": "2"], true,  2,    "2")
    // unknown value
    verifySelectField(SelectField("f", "label", list1), ["f": "4"], false, null, null)
    // unknown value too
    verifySelectField(SelectField("f", "label", list1), [:],        false, null, null)

    Obj[] list2 := [["Male"], ["Female"]]
    verifySelectField(SelectField("f", "label", list2), ["f": "Female"], true,  "Female", "Female")
    verifySelectField(SelectField("f", "label", list2), ["f": "Tree"],   false, null,     null)

    Obj[] list3 := [[1, "Male"], [2, "Female"]]
    verifySelectField(SelectField("f", "label", list3), ["f": "1"],    true,  1,    "1")
    verifySelectField(SelectField("f", "label", list3), ["f": "2"],    true,  2,    "2")
    verifySelectField(SelectField("f", "label", list3), ["f": "Male"], false, null, null)
    verifySelectField(SelectField("f", "label", list3), ["f": null],   false, null, null)
    
    // custom keys
    Obj[] list4 := [[1, "Male", "man"], [2, "Female", "woman"], [null, "-- Select --"]]
    verifySelectField(SelectField("f", "label", list4), ["f": "man"],   true,  1,    "man")
    verifySelectField(SelectField("f", "label", list4), ["f": "woman"], true,  2,    "woman")
    verifySelectField(SelectField("f", "label", list4), ["f": ""],      true,  null, "")
    verifySelectField(SelectField("f", "label", list4), [:],            true,  null, "")
    verifySelectField(SelectField("f", "label", list4), ["f": "1"],     false, null, "")
    verifySelectField(SelectField("f", "label", list4), ["f": "2"],     false, null, "")
  }

  Void verifyMultiselect(spectre::Field f, [Str:Str[]] data, Bool isValid, Obj? cleanedVal, Str?[] selectedKeys) {
    verifyField(f, data, isValid, cleanedVal)
    selected := Regex <|value="([^>]*)" checked="checked"|>
    m := selected.matcher(f.renderHtml)
    matches := 0
    while(m.find) {
      verify(selectedKeys.contains(m.group(1)), "${m.group(1)} not expected: " + f.renderHtml)
      matches += 1
    }
    verifyEq(selectedKeys.size, matches, f.renderHtml)
  }
  
  Void testMultiselectField() {
    Obj[] list := [["AAPL", "Apple", "1"], ["MSFT", "Microsoft", "2"], ["GOOG", "Google"], "DELL"]
    verifyMultiselect(MultiCheckboxField("f", "label", list), [:], true,  Obj?[,], [,])
    verifyMultiselect(MultiCheckboxField("f", "label", list), ["f": ["2", "GOOG"]], true,  Obj?["MSFT", "GOOG"], ["2", "GOOG"])
    verifyMultiselect(MultiCheckboxField("f", "label", list), ["f": ["2", "7", "GOOG"]], false,  null, ["2", "GOOG"])
    
    list = [[null, "-- Select --"], ["AAPL", "Apple", "1"], ["MSFT", "Microsoft", "2"], ["GOOG", "Google"], "DELL"]
    verifyMultiselect(MultiCheckboxField("f", "label", list), ["f": ["2", "GOOG"]], true,  Obj?["MSFT", "GOOG"], ["2", "GOOG"])
    verifyMultiselect(MultiCheckboxField("f", "label", list), [:], true,  Obj?[,], [,])
    verifyMultiselect(MultiCheckboxField("f", "label", list), ["f": [""]], true,  Obj?[null], [""])
    verifyMultiselect(MultiCheckboxField("f", "label", list), ["f": ["", "GOOG"]], true,  Obj?[null, "GOOG"], ["", "GOOG"])
  }
  
  Void testDateField() {
    verifyInputField(DateField("f", "label"), ["f": "01.01.2001"], true, Date.fromIso("2001-01-01"), "1.1.2001")
    verifyInputField(DateField("f", "label"), ["f": "12/31/2001"], true, Date.fromIso("2001-12-31"), "31.12.2001")
    verifyInputField(DateField("f", "label"), ["f": ""],           true, null, "")
    verifyInputField(DateField("f", "label"), ["f": "12/32/2001"], false, null, "12/32/2001")
    verifyInputField(DateField("f", "label"), [:],                 true,  null, "")
  }
    
  Void verifyDateSelect(spectre::Field f, [Str:Str] data, Bool isValid, Obj? cleanedVal, Str?[] selectedKeys) {
    verifyField(f, data, isValid, cleanedVal)
    regex := Regex <|<select(.*)</select><select(.*)</select><select(.*)</select>|>
    m := regex.matcher(f.renderHtml)
    m.find
    days := m.group(1)
    months := m.group(2)
    years := m.group(3)
    verify(days.contains("<option value=\"${selectedKeys[0]}\" selected=\"selected\">"), f.renderHtml)
    verify(months.contains("<option value=\"${selectedKeys[1]}\" selected=\"selected\">"), f.renderHtml)
    verify(years.contains("<option value=\"${selectedKeys[2]}\" selected=\"selected\">"), f.renderHtml)
  }
  
  Void testDateSelectField() {
    verifyDateSelect(DateSelectField("f", "label"), ["f[d]": "1" ,"f[m]": "1", "f[y]": "2001"], true, Date.fromIso("2001-01-01"), ["1", "1", "2001"])
    verifyDateSelect(DateSelectField("f", "label"), ["f[d]": "31" ,"f[m]": "2", "f[y]": "2001"], false, null, ["31", "2", "2001"])
  }
}
