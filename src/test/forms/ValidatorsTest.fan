
class ValidatorsTest: Test, FieldTestMixin {
    
  Void testStrValidators() {
    verifyInputField(StrField ("name", "label", [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "ab"], true, "ab", "ab")
    
    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "abcde"], true, "abcde", "abcde")

    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": ""], false, null, null)

    verifyInputField(StrField ("name", "label",  [MinLength(2), MaxLength(5)]), 
      ["name": ""], true, null, null)
    
    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "a"], false, null, "a")
    
    verifyInputField(StrField ("name", "label",  [Required(), MinLength(2), MaxLength(5)]), 
      ["name": "abcdef"], false, null, "abcdef")
  }
  
  Void testValueValidators() {
    verifyInputField(IntField ("name", "label", [Required(), MinValue(2), MaxValue(5)]), 
      ["name": "3"], true, 3, "3")
    
    verifyInputField(IntField ("name", "label", [Required(), MinValue(2), MaxValue(5)]), 
      ["name": "2"], true, 2, "2")
    
    verifyInputField(IntField ("name", "label", [Required(), MinValue(2), MaxValue(5)]), 
      ["name": "5"], true, 5, "5")

    verifyInputField(IntField ("name", "label",  [Required(), MinValue(2), MaxValue(5)]), 
      ["name": ""], false, null, null)

    verifyInputField(IntField ("name", "label",  [MinValue(2), MaxValue(5)]), 
      ["name": ""], true, null, null)
      
    verifyInputField(IntField ("name", "label",  [Required(), MinValue(2), MaxValue(5)]), 
      ["name": "a"], false, null, "a")
    
    verifyInputField(IntField ("name", "label",  [Required(), MinValue(2), MaxValue(5)]), 
      ["name": "abcdef"], false, null, "abcdef")
  }
  
  Void testClosureValidator() {
    validator := MatchesFunc{ it->isEven ? [,] : ["Even required"]}

    verifyInputField(IntField ("name", "label",  [validator]), ["name": "1"], false, null, "1")
    verifyInputField(IntField ("name", "label",  [validator]), ["name": "2"], true, 2, "2")
    verifyInputField(IntField ("name", "label",  [validator]), ["name": "fff"], false, null, "fff")
  }
  
  Void testRegexValidator() {
    validator := MatchesRegex(Regex.fromStr("H(e)+llo"), "You should salute me")

    verifyInputField(StrField ("name", "label",  [validator]), ["name": " Hello  "], true, "Hello", "Hello")
    verifyInputField(StrField ("name", "label",  [validator]), ["name": "Heeeello"], true, "Heeeello", "Heeeello")
    verifyInputField(StrField ("name", "label",  [validator]), ["name": "fff"], false, null, "fff")
  }
}
