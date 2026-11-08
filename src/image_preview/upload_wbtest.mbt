///|
extern "C" fn upload_fixture_png() -> Bytes = "moontown_preview_test_png"

///|
test "upload reconstructs pixels and refuses malformed, disguised and appended content" {
  let png = upload_fixture_png()
  assert_true(sanitize_upload(png, "image/png") is Some(_))
  assert_true(sanitize_upload(png, "image/jpeg") is None)
  assert_true(sanitize_upload(png, "image/webp") is None)
  assert_true(sanitize_upload(png, "image/svg+xml") is None)
  assert_true(
    sanitize_upload(png + b"<script>alert(1)</script>", "image/png") is None,
  )
  assert_true(
    sanitize_upload(
      b"<svg xmlns='http://www.w3.org/2000/svg'><script>evil()</script></svg>", "image/png",
    )
    is None,
  )
  assert_true(
    sanitize_upload(
      b"X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*", "image/png",
    )
    is None,
  )
  guard make(png, 768) is Some(webp) else { fail("fixture WebP failed") }
  guard sanitize_upload(webp, "image/webp") is Some(clean) else {
    fail("WebP upload failed")
  }
  assert_true(make(clean, 384) is Some(_))
}
