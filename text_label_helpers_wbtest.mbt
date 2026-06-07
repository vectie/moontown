///|
test "label from slug normalizes hyphen and underscore separators" {
  assert_eq(label_from_slug("white-tech_pavilion"), "white tech pavilion")
  assert_eq(label_from_slug("plain"), "plain")
}
