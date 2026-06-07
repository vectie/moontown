///|
test "json object copy ignores non-object values" {
  assert_eq(json_object_copy(None).length(), 0)
  assert_eq(json_object_copy(Some(Json::array([]))).length(), 0)
}

///|
test "nested json object upsert preserves sibling fields" {
  let base = @json.parse(
    "{\"jobs\":{\"profiles\":{\"existing\":{\"family\":\"old\"}},\"enabled\":true},\"keep\":\"yes\"}",
  ) catch {
    _ => fail("expected base config to parse")
  }
  let next = upsert_moonclaw_job_profile_json(base, "worker", {
    "family": "new",
    "role": "worker",
  })
  let text = next.stringify()
  assert_true(text.contains("\"existing\":{\"family\":\"old\"}"))
  assert_true(
    text.contains("\"worker\":{\"family\":\"new\",\"role\":\"worker\"}"),
  )
  assert_true(text.contains("\"enabled\":true"))
  assert_true(text.contains("\"keep\":\"yes\""))
}
