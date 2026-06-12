///|
async test "moonclaw optional json file reader handles missing invalid and valid files" {
  let root = "/tmp/moontown-moonclaw-json-file-io-wbtest"
  test_ignore_checked_command("rm", ["-rf", root])
  assert_true(moonclaw_read_optional_json_file("\{root}/missing.json") is None)
  moonclaw_write_text_file("\{root}/invalid.json", "{bad json")
  assert_true(moonclaw_read_optional_json_file("\{root}/invalid.json") is None)
  moonclaw_write_text_file("\{root}/valid.json", "{\"kind\":\"packet\"}")
  let parsed = match moonclaw_read_optional_json_file("\{root}/valid.json") {
    Some(json) => json
    None => fail("expected parsed json")
  }
  match parsed {
    Object(map) =>
      match map.get("kind") {
        Some(String(kind)) => assert_eq(kind, "packet")
        _ => fail("expected kind string")
      }
    _ => fail("expected object")
  }
}
