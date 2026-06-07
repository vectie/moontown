///|
test "live autonomy derived state gathers builder intermediates" {
  let goal = live_autonomy_watch_goal(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    book_id="research-opc",
    next_due_tick=10,
  )
  let record = live_autonomy_watcher_record(
    goal_id="watch-opc",
    tick=9,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::Update,
    delta_score=3,
    new_source_count=2,
    detail="accepted useful source",
    next_due_tick=70,
  )
  let derived = live_autonomy_derived_state(
    live_autonomy_build_input_fixture(
      standing_goals=[goal],
      watcher_records=[record],
      tick_summary="daemon probe",
      daemon_tick=Some(10),
      planbook_open=1,
    ),
  )
  assert_eq(derived.tick, 10)
  assert_eq(derived.status, "watching")
  assert_eq(derived.metrics.accepted_updates, 1)
  assert_eq(derived.metrics.due_goals, 1)
  assert_false(derived.waiting.stable_waiting)
  assert_true(
    derived.waiting.stable_waiting_blockers.contains("due standing goals: 1"),
  )
  assert_true(
    derived.waiting.stable_waiting_blockers.contains("PlanBook open gaps: 1"),
  )
  assert_eq(
    derived.latest_watcher_summary,
    "watch-opc -> Update sources=2 delta=3 next_due=10",
  )
  assert_true(derived.summary.contains("daemon probe; tick=10"))
  assert_true(derived.summary.contains("accepted_updates=1"))
  assert_true(derived.summary.contains("planbook_open=1"))
  assert_true(
    derived.next_actions.contains(
      "Dispatch due standing goals on the next daemon tick.",
    ),
  )
  assert_true(
    derived.next_actions.any(fn(action) {
      action.contains("PlanBook has 1 open self-build gap")
    }),
  )
}

///|
test "live autonomy spine assembly maps derived state into final record" {
  let input = live_autonomy_build_input_fixture(daemon_tick=Some(7))
  let derived = live_autonomy_derived_state(input)
  let spine = live_autonomy_spine_from(input, derived, 123UL)
  assert_eq(spine.generated_at_ms, 123UL)
  assert_eq(spine.tick, 7)
  assert_eq(spine.status, "watching")
  assert_eq(
    spine.summary,
    "test tick; tick=7 active=0 review=0 blocked=0 stable_waiting=true stable_waiting_observation_streak=1 accepted_updates=0 no_change=0 transient_infra_debt=0 enabled_goals=0 disabled_goals=0 planbook_open=0 template_requests=0 pending_templates=0",
  )
  assert_true(spine.stable_waiting)
  assert_eq(spine.stable_waiting_observation_streak, 1)
  assert_eq(
    spine.visual_projection_path,
    "/tmp/moontown-live-autonomy-build-input/visual-projection.json",
  )
  assert_eq(
    spine.journal_path,
    "/tmp/moontown-live-autonomy-build-input/town-journal.jsonl",
  )
  assert_eq(
    spine.digest_path,
    "/tmp/moontown-live-autonomy-build-input/live-digest.md",
  )
  assert_eq(
    spine.book_template_request_summary,
    "book_template_requests=0 pending=0 retry=0 installed=0 failed=0",
  )
  assert_eq(spine.latest_watcher_summary, "No watcher records yet.")
  assert_true(
    spine.next_actions.contains(
      "Town is watching; wait for the next real-world cadence or submit a new request.",
    ),
  )
}

///|
test "live autonomy builder maps metrics into blocker and action contexts" {
  let metrics = LiveAutonomyMetricCounts::{
    active_workers: 1,
    review: 2,
    blocked: 3,
    accepted_updates: 4,
    no_change: 5,
    failed: 6,
    transient_infrastructure_debt: 7,
    enabled_standing_goals: 8,
    disabled_standing_goals: 9,
    due_goals: 10,
  }
  let blockers = live_autonomy_stable_waiting_blockers_for(
    live_autonomy_blocker_context(metrics, 11, 12, 13, 14),
  )
  assert_true(blockers.contains("active workers or executions: 1"))
  assert_true(blockers.contains("PlanBook open gaps: 11"))
  assert_true(blockers.contains("failed book-template requests: 14"))
  let actions = live_autonomy_next_actions_for(
    live_autonomy_action_context(metrics, [], 11, 0, 13, 0),
  )
  assert_true(
    actions.contains("Dispatch due standing goals on the next daemon tick."),
  )
  assert_true(
    actions.any(fn(action) {
      action.contains("PlanBook has 11 open self-build gap")
    }),
  )
}
