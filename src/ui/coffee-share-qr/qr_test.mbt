///|
test "medium QR exposes a complete matrix for a short public link" {
  let code = @qr.matrix("hello")
  assert_eq(code[0], 21)
  assert_eq(code.length(), 442)
  assert_eq(code[1], 1)
  assert_eq(code[1 + 6], 1)
  assert_eq(code[1 + 21 * 6], 1)
  assert_eq(code[1 + 21 + 1], 0)
}
