///|
fn watcher_timeline_test_record(
  goal_id : String,
  tick : Int,
  decision? : String = "Update",
  task_id? : String? = Some("task-1"),
  run_id? : String? = Some("run-1"),
) -> WatcherRunRecordSnapshot {
  {
    goal_id,
    tick,
    target_book_id: "research-opc",
    decision,
    delta_score: 7,
    new_source_count: 2,
    checked_sources_count: Some(8),
    new_sources_found: Some(3),
    accepted_facts_count: Some(4),
    rejected_facts_count: Some(1),
    wiki_pages_changed_count: Some(5),
    book_changed: Some("yes"),
    detail: "First line\nsecond line",
    task_id,
    run_id,
    next_due_tick: tick + 30,
  }
}

///|
test "watcher timeline item view normalizes record labels" {
  let view = watcher_timeline_item_view(
    watcher_timeline_test_record("opc", 12, task_id=None, run_id=None),
  )
  assert_eq(view.class_name, "watch-timeline-item watch-decision-Update")
  assert_eq(view.title, "Update at tick 12")
  assert_eq(view.detail, "First line")
  assert_eq(view.goal_label, "goal opc")
  assert_eq(view.book_label, "book research-opc")
  assert_eq(view.checked_label, "checked 8")
  assert_eq(view.found_label, "found 3")
  assert_eq(view.accepted_label, "accepted 4")
  assert_eq(view.rejected_label, "rejected 1")
  assert_eq(view.wiki_label, "wiki 5")
  assert_eq(view.book_changed_label, "book changed yes")
  assert_eq(view.task_label, "task pending")
  assert_eq(view.run_label, "run pending")
}

///|
test "latest watcher timeline records keep newest first and cap limit" {
  let records = [
    watcher_timeline_test_record("a", 1),
    watcher_timeline_test_record("b", 2),
    watcher_timeline_test_record("c", 3),
    watcher_timeline_test_record("d", 4),
    watcher_timeline_test_record("e", 5),
    watcher_timeline_test_record("f", 6),
  ]
  let latest = latest_watcher_timeline_records(records, 5)
  assert_eq(latest.length(), 5)
  assert_eq(latest[0].tick, 6)
  assert_eq(latest[1].tick, 5)
  assert_eq(latest[4].tick, 2)
}
