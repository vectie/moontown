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
      decision=@core.WatcherDecisionKind::NoChange,
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
      decision=@core.WatcherDecisionKind::Update,
      detail="new source persisted",
      next_due_tick=17,
    ),
  )
  let records = load_watcher_run_records_file(path)
  assert_eq(records.length(), 2)
  assert_eq(records[0].decision, @core.WatcherDecisionKind::NoChange)
  assert_eq(records[1].decision, @core.WatcherDecisionKind::Update)
  assert_eq(consecutive_no_change_count(records), 0)
  assert_eq(consecutive_no_change_count([records[0]]), 1)
}
