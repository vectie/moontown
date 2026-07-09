///|
test "class suffix helper includes suffix only when enabled" {
  assert_eq(class_suffix_when(true, " selected"), " selected")
  assert_eq(class_suffix_when(false, " selected"), "")
  assert_eq(class_suffix_when(true, " is-active"), " is-active")
}
