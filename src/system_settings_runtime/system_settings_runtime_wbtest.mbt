///|
async test "settings update persists revision audit and effective values" {
  let path = "/tmp/moontown-system-settings-runtime-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  let initial = system_settings_management_snapshot(path~)
  assert_true(initial.stringify().contains("\"revision\":1"))
  let proposed = {
    ..@system_settings.default_system_settings(),
    max_concurrent_tasks: 20,
    max_live_external_executions: 10,
  }
  let request : Json = {
    "expected_revision": (1 : Int).to_json(),
    "values": proposed.to_json(),
  }
  let updated = update_system_settings(
    request.stringify(),
    actor_id="admin-a",
    now_ms=100UL,
    path~,
  )
  assert_true(updated.stringify().contains("max_live_external_executions"))
  assert_eq(
    load_and_install_system_settings(path~).max_live_external_executions,
    10,
  )
  @fs.remove(path) catch {
    _ => ()
  }
}

///|
async test "settings update rejects a stale revision" {
  let path = "/tmp/moontown-system-settings-conflict-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  ignore(system_settings_management_snapshot(path~))
  let request : Json = {
    "expected_revision": (2 : Int).to_json(),
    "values": @system_settings.default_system_settings().to_json(),
  }
  let body = request.stringify()
  try
    update_system_settings(body, actor_id="admin-a", now_ms=100UL, path~)
  catch {
    error => assert_true("\{error}".contains("refresh and retry"))
  } noraise {
    _ => fail("stale revision must fail")
  }
  @fs.remove(path) catch {
    _ => ()
  }
}
