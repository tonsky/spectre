
class ValidatorsTest: Test, FieldTestMixin {
    
  Void testStrValidators() {
    verifyField(StrField ("name", "label", [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "ab"], true, "ab", "ab")
    
    verifyField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "abcde"], true, "abcde", "abcde")

    verifyField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": ""], false, null, "")
    
    verifyField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "a"], false, null, "a")
    
    verifyField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "abcdef"], false, null, "abcdef")
  }
}
