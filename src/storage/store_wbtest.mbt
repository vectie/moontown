///|
async test "watcher ledger appends and reads jsonl records" {
  let path = "/tmp/moontown-watcher-ledger-test.jsonl"
  @fs.write_file(
    path,
    @encoding/utf8.encode(""),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  append_watcher_run_record_file(
    path,
    @core.WatcherRunRecord::new(
      goal_id="watch-opc-news",
      tick=1,
      target_book_id="research-opc",
      decision=NoChange,
      detail="no useful delta",
      next_due_tick=9,
    ),
  )
  append_watcher_run_record_file(
    path,
    @core.WatcherRunRecord::new(
      goal_id="watch-opc-news",
      tick=9,
      target_book_id="research-opc",
      decision=Update,
      detail="new source persisted",
      next_due_tick=17,
    ),
  )
  let records = load_watcher_run_records_file(path)
  assert_eq(records.length(), 2)
  assert_eq(records[0].decision, NoChange)
  assert_eq(records[1].decision, Update)
  assert_eq(consecutive_no_change_count(records), 0)
  assert_eq(consecutive_no_change_count([records[0]]), 1)
}

///|
async test "standing goals accept the UI operator request contract" {
  let path = "/tmp/moontown-ui-standing-goal-contract.json"
  let json = "[{\"id\":\"standing-goal-ui\",\"title\":\"UI research\",\"prompt\":\"Research the request.\",\"target_book_id\":\"research-agent-work-projection\",\"cadence_ticks\":1000000,\"next_due_tick\":0,\"enabled\":true,\"source_policy\":\"web-first\",\"quality_threshold\":85}]"
  @fs.write_file(
    path,
    @encoding/utf8.encode(json),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  guard load_standing_goals_file(path) is Some([goal]) else {
    fail("UI standing-goal JSON did not satisfy MoonTown's durable contract")
  }
  assert_eq(goal.id, "standing-goal-ui")
  assert_eq(goal.next_due_tick, 0)
  assert_eq(goal.last_run_tick, None)
}

///|
async test "accepted operator ledger recovers a missing standing goal" {
  let path = "/tmp/moontown-ui-operator-request-contract.jsonl"
  let accepted = "{\"id\":\"operator-ui\",\"status\":\"accepted\",\"created_at\":\"2026-07-28T00:00:00.000Z\",\"title\":\"UI research\",\"prompt\":\"Research the request.\",\"target_book_id\":\"research-agent-work-projection\",\"cadence_ticks\":1000000,\"source_policy\":\"web-first\",\"quality_threshold\":85,\"standing_goal_id\":\"standing-goal-ui\"}"
  let failed = "{\"id\":\"operator-failed\",\"status\":\"failed\",\"title\":\"Failed research\",\"prompt\":\"Do not recover.\",\"target_book_id\":\"research-opc\",\"cadence_ticks\":60,\"source_policy\":\"web-first\",\"quality_threshold\":85,\"standing_goal_id\":\"standing-goal-failed\"}"
  @fs.write_file(
    path,
    @encoding/utf8.encode("\{accepted}\nnot-json\n\{failed}\n"),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let existing = default_standing_goals()
  let merged = merge_accepted_operator_request_goals(existing, path~)
  assert_eq(merged.length(), 2)
  guard @core.standing_goal_registry_find(merged, "standing-goal-ui")
    is Some(recovered) else {
    fail("accepted operator request did not recover its standing goal")
  }
  assert_eq(recovered.next_due_tick, 0)
  assert_eq(recovered.last_run_tick, None)
  assert_true(
    @core.standing_goal_registry_find(merged, "standing-goal-failed") is None,
  )
}

///|
async test "watcher ledger derives snapshot-relative directory and appends by goal" {
  let root = "/tmp/moontown-watcher-ledger-dir-test"
  assert_eq(snapshot_base_dir("\{root}/town.json"), root)
  assert_eq(snapshot_base_dir("town.json"), moontown_product_state_dir())
  assert_eq(moonsuite_product_id(), "moontown")
  let suite_root = "/tmp/moontown-suite"
  let book_root = suite_root + "/books/research-demo"
  assert_eq(
    moontown_product_state_dir_for_workspace_root(book_root),
    "/tmp/moontown-suite/.moonsuite/products/moontown",
  )
  assert_eq(
    moontown_product_artifact_for_workspace_root(book_root, "civic/status.json"),
    "/tmp/moontown-suite/.moonsuite/products/moontown/civic/status.json",
  )
  assert_true(moontown_workspace_root_is_suite_book(book_root))
  assert_true(moontown_workspace_root_is_suite_book("books/research-demo"))
  assert_false(moontown_workspace_root_is_suite_book("/tmp/moontown-suite"))
  assert_false(moontown_workspace_root_is_suite_book(""))
  assert_false(
    moontown_product_artifact_for_workspace_root(book_root, "civic/status.json").contains(
      "/books/research-demo/.moonsuite",
    ),
  )
  assert_eq(
    moontown_product_service_path(),
    moontown_product_artifact("service.json"),
  )
  assert_eq(
    moontown_product_tmp_dir(),
    @moonsuite.product_home_for_workspace_root(
      moontown_active_workspace_root(),
      moonsuite_product_id(),
    ).tmp_path,
  )
  let previous_suite_root = @env.get_env_var("MOONTOWN_SUITE_ROOT")
  let previous_shared_suite_root = @env.get_env_var("MOONSUITE_ROOT")
  @env.unset_env_var("MOONTOWN_SUITE_ROOT")
  @env.set_env_var("MOONSUITE_ROOT", "/tmp/moonsuite-env-suite")
  assert_eq(moontown_active_workspace_root(), "/tmp/moonsuite-env-suite")
  @env.set_env_var("MOONTOWN_SUITE_ROOT", "/tmp/moontown-env-suite")
  assert_eq(moontown_active_workspace_root(), "/tmp/moontown-env-suite")
  assert_eq(
    moontown_product_state_dir(),
    "/tmp/moontown-env-suite/.moonsuite/products/moontown",
  )
  assert_eq(
    moontown_product_artifact("town.json"),
    "/tmp/moontown-env-suite/.moonsuite/products/moontown/town.json",
  )
  match previous_suite_root {
    Some(root) => @env.set_env_var("MOONTOWN_SUITE_ROOT", root)
    None => @env.unset_env_var("MOONTOWN_SUITE_ROOT")
  }
  match previous_shared_suite_root {
    Some(root) => @env.set_env_var("MOONSUITE_ROOT", root)
    None => @env.unset_env_var("MOONSUITE_ROOT")
  }
  assert_eq(default_snapshot_path(), moontown_product_artifact("town.json"))
  assert_eq(
    default_standing_goal_path(),
    moontown_product_artifact("standing-goals.json"),
  )
  assert_eq(default_watcher_ledger_dir(), moontown_product_artifact("watchers"))
  assert_eq(
    moontown_product_display_artifact("planbook/latest-validation.md"),
    ".moonsuite/products/moontown/planbook/latest-validation.md",
  )
  assert_eq(
    moontown_product_display_state_dir(),
    ".moonsuite/products/moontown",
  )
  let ledger_dir = watcher_ledger_dir_for_snapshot("\{root}/town.json")
  assert_eq(ledger_dir, "\{root}/watchers")
  assert_eq(
    watcher_ledger_dir_for_snapshot("town.json"),
    default_watcher_ledger_dir(),
  )
  let goal_id = "Watch OPC News!"
  @fs.mkdir(root, permission=0o755) catch {
    _ => ()
  }
  @fs.mkdir(ledger_dir, permission=0o755) catch {
    _ => ()
  }
  @fs.write_file(
    watcher_ledger_path(goal_id, dir=ledger_dir),
    @encoding/utf8.encode(""),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  append_watcher_run_record(
    goal_id,
    @core.WatcherRunRecord::new(
      goal_id~,
      tick=3,
      target_book_id="research-opc",
      decision=NoChange,
      detail="no useful delta",
      next_due_tick=63,
    ),
    dir=ledger_dir,
  )
  let records = load_watcher_run_records(goal_id, dir=ledger_dir)
  assert_eq(records.length(), 1)
  assert_eq(records[0].tick, 3)
}
