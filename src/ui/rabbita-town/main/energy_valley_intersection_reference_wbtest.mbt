///|
test "intersection review marker glyphs distinguish junction kinds" {
  assert_eq(intersection_reference_kind_glyph("t"), "T")
  assert_eq(intersection_reference_kind_glyph("cross"), "+")
  assert_eq(intersection_reference_kind_glyph("complex"), "*")
  assert_eq(intersection_reference_kind_glyph("unknown"), "")
}
