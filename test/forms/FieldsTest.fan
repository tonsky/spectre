
mixin FieldTestMixin {
  abstract Void verify(Bool cond, Str? msg := null)
  abstract Void verifyEq(Obj? o1, Obj? o2, Str? msg := null)
  
  Void verifyField(spectre::Field f, [Str:Str] data, Bool isValid, Obj? cleanedVal, Str? renderedVal) {
    f.bind(data)
    verifyEq(f.clean, isValid)
    verifyEq(f.isValid, isValid)
    verify(f.errors.isEmpty == isValid, "$f.errors")
    verifyEq(f.cleanedData, cleanedVal)
    if(renderedVal == null)
      verify(!f.renderHtml.contains("value=\""), f.renderHtml)
    else
      verify(f.renderHtml.contains("value=\"$renderedVal\""), f.renderHtml)
  }
}

class FieldsTest: Test, FieldTestMixin {
  Void testBasicLogic() {
    // basic logic
    verifyField(StrField("name"), ["x": "y", "name": "val", "z": "t"],
                true, "val", "val")
    
    verifyField(StrField("name"), ["x": "y", "name": "", "z": "t"],
                true, null, null) //FIXME
    
    verifyField(StrField("name"), ["x": "y", "z": "t"],
                true, null, null)
    
    verifyField(IntField("name"), ["x": "y", "name": "", "z": "t"],
                true, null, null) //FIXME
    
    // incorrect value
    verifyField(IntField("name"), ["x": "y", "name": "val", "z": "t"],
                false, null, "val") // "val" should be rendered back
  }
  
  Void testInitialsLogic() {
    // initial
    f := IntField("name") { initialData=25 }
    verify(f.renderHtml.contains("value=\"25\""), f.renderHtml)

    verifyField(f, ["x": "y", "name": "21", "z": "t"],
                true, 21, "21")
    
    verifyField(IntField("name") { initialData=25 }, ["x": "y", "name": "val", "z": "t"],
                false, null, "val") // "val" should be rendered back

    verifyField(IntField("name") { initialData=25 }, ["x": "y", "z": "t"],
                true, null, null) // shouldn't render value
  }
  
  Void testValidationLogic() {
    // validations
    verifyField(StrField("name", "label", [Required()]), ["x": "y", "name": "val", "z": "t"],
                true, "val", "val")

    verifyField(StrField("name", "label", [Required()]), ["x": "y", "z": "t"],
                false, null, null) //FIXME
    
    verifyField(StrField("name", "label", [Required()]), ["x": "y", "name": "", "z": "t"],
                false, null, "") //FIXME
    
    verifyField(StrField("name", "label", [Required()]) { initialData = "in" }, ["x": "y", "z": "t"],
                false, null, null) //FIXME
  }

}
