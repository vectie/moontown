///|
async test "login during generation preserves the claimed owner on success and reconciliation" {
  let root = @fs.tmpdir(prefix="creative-claim-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/event.json"
  let config = { ..fixture_config(), guest_generation: Some(true), }
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateNew,
  )
  let guest = "guest:" + hash("visitor-capability")
  let payload : Json = { "prompt": "coffee", "intent": "stable-across-login" }
  let queued = transition(
    empty(config),
    config,
    "generate",
    payload,
    200UL,
    guest,
    false,
  )
  let dispatched = {
    ..queued.generations[0],
    state: "running",
    started_ms: 200UL,
  }
  save(path, { ..queued, generations: [dispatched], })
  ignore(
    execute(
      "snapshot",
      {},
      300UL,
      Some("alice"),
      false,
      path,
      config_path,
      guest_actor=Some(guest),
    ),
  )
  finish(path, config, dispatched, None, 400UL)
  assert_eq(read(path, config).generations[0].actor, "alice")
  finish(
    path,
    config,
    dispatched,
    Some(("fixture-output", preview_fixture())),
    500UL,
  )
  let stored = read(path, config)
  assert_eq(stored.generations[0].actor, "alice")
  assert_eq(stored.generations[0].state, "completed")
  assert_eq(
    transition(stored, config, "generate", payload, 600UL, "alice", false).generations.length(),
    1,
  )
  assert_true(
    snapshot(stored, config, 600UL, Some(guest), false)
    is { "generations": [], .. },
  )
}
