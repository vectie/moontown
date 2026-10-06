///|
fn native_wenyu_adapter_test_result() -> BookResult {
  BookResult::new(
    result_id="wenyu-goal-1-code-patch",
    summary="Verified exact source changes; awaiting human review.",
    artifacts=["wiki/CODE_PATCH.md", "wiki/TEST_RESULTS.md"],
    requires_review=true,
    notify_town=true,
  )
}

///|
test "native Wenyu envelope binds exact unchanged BookResult and stable native identity" {
  let result = native_wenyu_adapter_test_result()
  let request_digest = @crypto.bytes_to_hex_string(
    @crypto.sha256(@encoding/utf8.encode("request")),
  )
  let first = native_wenyu_result_envelope(
    result, "native-work-1", request_digest,
  )
  let second = native_wenyu_result_envelope(
    result, "native-work-1", request_digest,
  )
  assert_eq(first, second)
  guard first is Object(fields) else { fail("expected envelope") }
  assert_eq(fields["book_result"], result.to_json())
  guard fields["native_import"] is Object(metadata) else {
    fail("expected identity")
  }
  assert_eq(metadata["contract"], "moontown.wenyu.import.v1".to_json())
  assert_eq(metadata["work_id"], "native-work-1".to_json())
  assert_eq(metadata["request_digest"], request_digest.to_json())
  assert_eq(
    metadata["payload_digest"],
    @crypto.bytes_to_hex_string(
      @crypto.sha256(@encoding/utf8.encode(result.to_json().stringify())),
    ).to_json(),
  )
  assert_eq(decode_book_result_payload(first), Some(result))
  assert_true(!result.to_json().stringify().contains("native_import"))
}

///|
test "native Wenyu envelope rejects out of scope result without changing legacy decoding" {
  let result = native_wenyu_adapter_test_result()
  let digest = @crypto.bytes_to_hex_string(
    @crypto.sha256(@encoding/utf8.encode("request")),
  )
  let legacy = { ..result, requires_review: false, notify_town: false, }
  assert_eq(decode_book_result_payload(legacy.to_json()), Some(legacy))
  try native_wenyu_result_envelope(legacy, "native-work-1", digest) catch {
    _ => ()
  } noraise {
    _ => fail("native Wenyu scope must fail closed")
  }
  try
    native_wenyu_result_envelope(result, "native-work-1", "sha256:" + digest)
  catch {
    _ => ()
  } noraise {
    _ => fail("request must use raw SHA-256 hex")
  }
}
