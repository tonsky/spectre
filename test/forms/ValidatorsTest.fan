
class ValidatorsTest: Test, FieldTestMixin {
    
  Void testStrValidators() {
    verifyInputField(StrField ("name", "label", [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "ab"], true, "ab", "ab")
    
    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "abcde"], true, "abcde", "abcde")

    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": ""], false, null, null)
    
    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "a"], false, null, "a")
    
    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "abcdef"], false, null, "abcdef")
  }
}
