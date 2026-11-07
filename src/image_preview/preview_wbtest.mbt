///|
extern "C" fn fixture() -> Bytes = "moontown_preview_test_png"

///|
test "both derivatives preserve aspect ratio and the original" {
  let png = fixture()
  assert_true(png.length() > 32)
  let before = @base64.encode(png)
  let thumbnail = make(png, 384).unwrap()
  let preview = make(png, 768).unwrap()
  assert_eq(@base64.encode(png), before)
  assert_true(thumbnail.has_prefix(b"RIFF"))
  assert_eq(dimensions(thumbnail), Some((384, 192)))
  assert_eq(dimensions(preview), Some((768, 384)))
  assert_eq(make(png[:40].to_owned(), 384), None)
}
