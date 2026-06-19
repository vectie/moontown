///|
test "standing watch book result paths use storage snapshot base" {
  assert_eq(
    standing_watch_book_result_path("town.json", "standing-watch-a"),
    ".moontown/book-results/standing-watch-a.json",
  )
  assert_eq(
    standing_watch_book_result_path(
      "/tmp/moontown/town.json", "standing-watch-b",
    ),
    "/tmp/moontown/book-results/standing-watch-b.json",
  )
}

///|
async test "standing watch review queue auto-closes no-change keeper markers" {
  let root = "/tmp/moontown-standing-watch-auto-triage-no-change"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = standing_watch_goal_fixture(
    id="watch-auto-triage",
    title="Auto triage",
    prompt="watch auto triage",
    book_id="research-opc",
  )
  write_standing_watch_history_marker(
    book_root, "provider-standing-watch-auto", "no_change", 12, 0, "no",
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-watch-auto-triage-tick-12",
      packet_path="packet.json",
      run_id=Some("run-auto"),
      status=ReviewQueued,
      summary="Workflow completed",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, Completed)
  assert_true(
    state.executions[0].summary.contains("keeper_auto_triage: accepted"),
  )
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
  let records = @storage.load_watcher_run_records(
    "watch-auto-triage",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some("standing-watch-auto-triage-tick-12") &&
      record.decision == NoChange
    }),
  )
}

///|
async test "standing watch review queue closes deferred infrastructure markers" {
  let root = "/tmp/moontown-standing-watch-deferred-review-close"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = standing_watch_goal_fixture(
    id="watch-deferred",
    title="Deferred watcher",
    prompt="watch deferred",
    book_id="research-opc",
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-watch-deferred-tick-88",
      packet_path="packet.json",
      status=ReviewQueued,
      summary="Standing watch execution failed.\nRUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\nSystemStore::save_job_proposals\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true\nnext_check_hint: immediate",
      requires_review=true,
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, Completed)
  assert_eq(state.executions[0].requires_review, false)
  assert_true(
    state.executions[0].summary.contains("keeper_auto_triage: deferred"),
  )
}

///|
async test "standing watch auto triage keeps weak updates in review" {
  let root = "/tmp/moontown-standing-watch-auto-triage-weak-update"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = standing_watch_goal_fixture(
    id="watch-weak-update",
    title="Weak update",
    prompt="watch weak update",
    book_id="research-opc",
  )
  write_standing_watch_history_marker(
    book_root,
    "provider-standing-watch-weak",
    "update",
    42,
    1,
    "yes",
    next_check_hint="review",
    accepted_facts_count=1,
    wiki_pages_changed_count=1,
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-watch-weak-update-tick-12",
      packet_path="packet.json",
      run_id=Some("run-weak"),
      status=ReviewQueued,
      summary="Workflow completed",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, ReviewQueued)
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: update"),
  )
  assert_true(
    !state.executions[0].summary.contains("keeper_auto_triage: accepted"),
  )
}

///|
async test "standing watch auto triage closes empty persisted book result" {
  let root = "/tmp/moontown-standing-watch-auto-triage-empty-result"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = standing_watch_goal_fixture(
    id="watch-empty-result",
    title="Empty result",
    prompt="watch empty result",
    book_id="research-opc",
  )
  let result = @moonbook.BookResult::new(
    task_id="standing-watch-empty-result-tick-12",
    summary="MoonClaw run completed: Workflow completed workspace=/tmp/run",
    artifacts=["run-empty"],
    memory_candidates=[],
    requires_review=false,
    notify_town=false,
  )
  @support.write_text_file(
    "\{root}/book-results/standing-watch-empty-result-tick-12.json",
    result.to_json().stringify(),
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-watch-empty-result-tick-12",
      packet_path="packet.json",
      run_id=Some("run-empty"),
      status=ReviewQueued,
      summary="Workflow completed",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, Completed)
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
  assert_true(
    state.executions[0].summary.contains(
      "empty, non-review operational completion",
    ),
  )
}
