
class UtilTest : Test, Util {
  Void testZip() {
    verifyEq(zip([[1,2,3], [4,5,6]]), Obj?[Obj?[1,4], Obj?[2,5], Obj?[3,6]])
    
    // check for type agnostic
    verifyEq(zip([[1,2,3], ["a","b","c"]]), Obj?[Obj?[1,"a"], Obj?[2,"b"], Obj?[3,"c"]])
    
    // check for different lengths
    verifyEq(zip([[1,2,3,4], ["a","b","c"]]), Obj?[Obj?[1,"a"], Obj?[2,"b"], Obj?[3,"c"]])
    verifyEq(zip([[1,2,3,4,5], ["a","b","c"]]), Obj?[Obj?[1,"a"], Obj?[2,"b"], Obj?[3,"c"]])
    verifyEq(zip([[1,2,3], ["a","b","c","d"]]), Obj?[Obj?[1,"a"], Obj?[2,"b"], Obj?[3,"c"]])
    verifyEq(zip([[1,2,3], ["a","b","c","d","e"]]), Obj?[Obj?[1,"a"], Obj?[2,"b"], Obj?[3,"c"]])
    
    // edge cases
    verifyEq(zip([[1,2,3], [,]]), Obj?[,])
    verifyEq(zip([[1,2,3]]), Obj?[Obj?[1], Obj?[2], Obj?[3]])
    verifyEq(zip([[,], [,]]), Obj?[,])
    verifyEq(zip([[,]]), Obj?[,])
  }
}
