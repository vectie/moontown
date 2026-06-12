///|
async test "optional json file reader handles missing invalid and valid files" {
  let root = "/tmp/moontown-file-io-json-wbtest"
  let missing_path = "\{root}/missing.json"
  let invalid_path = "\{root}/invalid.json"
  let valid_path = "\{root}/valid.json"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  assert_true(read_optional_json_file(missing_path) is None)
  write_text_file(invalid_path, "{not json")
  assert_true(read_optional_json_file(invalid_path) is None)
  write_text_file(valid_path, "{\"name\":\"moontown\",\"count\":2}")
  let parsed = match read_optional_json_file(valid_path) {
    Some(json) => json
    None => fail("expected parsed json")
  }
  let object = match parsed {
    Object(map) => map
    _ => fail("expected object")
  }
  assert_eq(json_object_string(object, "name").unwrap(), "moontown")
}

///|
async test "json file empty object reader preserves fallback contract" {
  let root = "/tmp/moontown-file-io-json-empty-object-wbtest"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  let missing = read_json_file_or_empty_object("\{root}/missing.json")
  assert_true(missing is Object(_))
  write_text_file("\{root}/invalid.json", "{bad json")
  let invalid = read_json_file_or_empty_object("\{root}/invalid.json")
  assert_true(invalid is Object(_))
  write_text_file("\{root}/valid.json", "{\"enabled\":true}")
  let valid = read_json_file_or_empty_object("\{root}/valid.json")
  assert_true(valid.stringify().contains("\"enabled\":true"))
}
