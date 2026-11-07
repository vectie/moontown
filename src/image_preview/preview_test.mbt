///|
test "previews reject unbounded and unsupported input before decoding" {
  assert_eq(@image_preview.make(b"not a png", 384), None)
  assert_eq(@image_preview.make(Bytes::make(64, 0), 384), None)
  assert_eq(@image_preview.make(Bytes::make(64, 0), 1), None)
  assert_eq(@image_preview.dimensions(b"not webp"), None)
}
