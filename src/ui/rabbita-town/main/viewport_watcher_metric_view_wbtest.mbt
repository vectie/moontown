///|
fn watcher_metric_view_test_record() -> WatcherRunRecordSnapshot {
  {
    goal_id: "research-opc",
    tick: 5,
    target_book_id: "research-opc",
    decision: "Update",
    delta_score: 9,
    new_source_count: 4,
    checked_sources_count: Some(10),
    new_sources_found: Some(6),
    accepted_facts_count: Some(3),
    rejected_facts_count: Some(1),
    wiki_pages_changed_count: Some(2),
    book_changed: Some("yes"),
    detail: "Updated baseline\nextra detail",
    task_id: None,
    run_id: None,
    next_due_tick: 35,
  }
}

///|
test "latest watcher metric view centralizes missing fallback" {
  let view = latest_watcher_metric_view(None)
  assert_eq(view.decision, "Waiting")
  assert_eq(view.sources, "0")
}

///|
test "latest watcher metric view centralizes present record labels" {
  let view = latest_watcher_metric_view(Some(watcher_metric_view_test_record()))
  assert_eq(view.decision, "Update")
  assert_eq(view.sources, "4")
}
