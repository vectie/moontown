///|
fn viewport_portal_test_goal() -> StandingGoalSnapshot {
  {
    id: "research-opc",
    title: "Research OPC",
    prompt: "Watch OPC.",
    target_book_id: Some("research-opc"),
    cadence_ticks: 30,
    next_due_tick: 14,
    last_run_tick: Some(4),
    enabled: true,
    source_policy: "test",
    quality_threshold: 80,
  }
}

///|
fn viewport_portal_test_record() -> WatcherRunRecordSnapshot {
  {
    goal_id: "research-opc",
    tick: 8,
    target_book_id: "research-opc",
    decision: "NoChange",
    delta_score: 0,
    new_source_count: 1,
    checked_sources_count: Some(5),
    new_sources_found: Some(1),
    accepted_facts_count: Some(0),
    rejected_facts_count: Some(1),
    wiki_pages_changed_count: Some(0),
    book_changed: Some("no"),
    detail: "No material change.",
    task_id: None,
    run_id: None,
    next_due_tick: 38,
  }
}

///|
fn viewport_portal_test_daemon() -> DaemonSnapshot {
  {
    daemon_id: "daemon-test",
    lease_owner: "test",
    tick_sequence: 9,
    last_heartbeat_event_count: 1,
    active_goal_ids: ["research-opc"],
    jobs: [],
  }
}

///|
test "wenyu viewport portal view uses fallback without watch state" {
  let model = { ..init_model(), standing_goals: [], watcher_records: [] }
  let view = wenyu_viewport_portal_view(model, [])
  assert_eq(view.latest_decision, "Waiting")
  assert_eq(view.latest_sources, "0")
  assert_eq(view.next_check, "not scheduled")
  assert_eq(view.active_work, 0)
}

///|
test "wenyu viewport portal view uses watcher and standing goal state" {
  let model = {
    ..init_model(),
    daemon_snapshot: Some(viewport_portal_test_daemon()),
    standing_goals: [viewport_portal_test_goal()],
    watcher_records: [viewport_portal_test_record()],
  }
  let view = wenyu_viewport_portal_view(model, [])
  assert_eq(view.latest_decision, "NoChange")
  assert_eq(view.latest_sources, "1")
  assert_eq(view.next_check, "5 ticks")
}
