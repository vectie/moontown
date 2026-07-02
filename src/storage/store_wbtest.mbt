///|
async test "watcher ledger appends and reads jsonl records" {
  let path = "/tmp/moontown-watcher-ledger-test.jsonl"
  @fs.write_file(path, @encoding/utf8.encode(""), create=0o644, truncate=true)
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
      @os.cwd() catch {
        _ => "."
      },
      moonsuite_product_id(),
    ).tmp_path,
  )
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
    create=0o644,
    truncate=true,
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
