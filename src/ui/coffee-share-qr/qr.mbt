///|
pub fn matrix(text : String) -> Array[Int32] {
  let code = @lib.encode_medium(text)
  let result = [code.size()]
  for y in 0..<code.size() {
    for x in 0..<code.size() {
      result.push(if code.is_black(x, y) { 1 } else { 0 })
    }
  }
  result
}
