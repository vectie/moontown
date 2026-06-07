///|
async fn moonbook_test_ignore_checked_command(
  command : String,
  args : Array[String],
) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}

///|
async test "moonbook optional json file reader handles missing invalid and valid files" {
  let root = "/tmp/moontown-moonbook-json-file-io-wbtest"
  moonbook_test_ignore_checked_command("rm", ["-rf", root])
  assert_true(moonbook_read_optional_json_file("\{root}/missing.json") is None)
  write_workspace_text("\{root}/invalid.json", "{bad json")
  assert_true(moonbook_read_optional_json_file("\{root}/invalid.json") is None)
  write_workspace_text("\{root}/valid.json", "{\"kind\":\"catalog\"}")
  let parsed = match moonbook_read_optional_json_file("\{root}/valid.json") {
    Some(json) => json
    None => fail("expected parsed json")
  }
  match parsed {
    Object(map) =>
      match map.get("kind") {
        Some(String(kind)) => assert_eq(kind, "catalog")
        _ => fail("expected kind string")
      }
    _ => fail("expected object")
  }
}

///|
async test "moonbook directory helper creates nested workspace paths" {
  let root = "/tmp/moontown-moonbook-directory-wbtest"
  moonbook_test_ignore_checked_command("rm", ["-rf", root])
  ensure_directory("\{root}/book/site/generated")
  assert_true(@fs.exists("\{root}/book"))
  assert_true(@fs.exists("\{root}/book/site"))
  assert_true(@fs.exists("\{root}/book/site/generated"))
}
