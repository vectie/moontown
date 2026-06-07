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
fn watcher_metric_view_sparse_record() -> WatcherRunRecordSnapshot {
  {
    goal_id: "research-opc",
    tick: 5,
    target_book_id: "research-opc",
    decision: "NoChange",
    delta_score: 0,
    new_source_count: 0,
    checked_sources_count: None,
    new_sources_found: None,
    accepted_facts_count: None,
    rejected_facts_count: None,
    wiki_pages_changed_count: None,
    book_changed: None,
    detail: "No change",
    task_id: None,
    run_id: None,
    next_due_tick: 35,
  }
}

///|
test "watcher record metric labels normalize dense and sparse fields" {
  let dense = watcher_record_metric_labels(watcher_metric_view_test_record())
  assert_eq(dense.sources, "4")
  assert_eq(dense.checked, "10")
  assert_eq(dense.found, "6")
  assert_eq(dense.accepted, "3")
  assert_eq(dense.rejected, "1")
  assert_eq(dense.wiki, "2")
  assert_eq(dense.book_changed, "yes")
  let sparse = watcher_record_metric_labels(watcher_metric_view_sparse_record())
  assert_eq(sparse.sources, "0")
  assert_eq(sparse.checked, "n/a")
  assert_eq(sparse.found, "n/a")
  assert_eq(sparse.accepted, "n/a")
  assert_eq(sparse.rejected, "n/a")
  assert_eq(sparse.wiki, "n/a")
  assert_eq(sparse.book_changed, "unknown")
}

///|
test "latest watcher metric view centralizes missing fallback" {
  let view = latest_watcher_metric_view(None)
  assert_eq(view.decision, "Waiting")
  assert_eq(view.sources, "0")
  assert_eq(view.checked, "n/a")
  assert_eq(view.accepted, "n/a")
  assert_eq(view.wiki, "n/a")
  assert_eq(view.book_changed, "unknown")
  assert_eq(view.detail, "No durable watcher ledger has been published yet.")
}

///|
test "latest watcher metric view centralizes present record labels" {
  let view = latest_watcher_metric_view(Some(watcher_metric_view_test_record()))
  assert_eq(view.decision, "Update")
  assert_eq(view.sources, "4")
  assert_eq(view.checked, "10")
  assert_eq(view.accepted, "3")
  assert_eq(view.wiki, "2")
  assert_eq(view.book_changed, "yes")
  assert_eq(view.detail, "Updated baseline")
}
