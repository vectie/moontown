///|
test "live autonomy build tick prefers daemon override then state tick" {
  let empty_state = live_autonomy_empty_test_state()
  assert_eq(
    live_autonomy_build_tick(
      live_autonomy_build_input_fixture(state=empty_state, daemon_tick=Some(99)),
    ),
    99,
  )
  let event_state = @test_fixtures.visual_projection_test_state(
    worker_status=Idle,
    execution_status=Completed,
  )
  assert_eq(
    live_autonomy_build_tick(
      live_autonomy_build_input_fixture(state=event_state, daemon_tick=None),
    ),
    live_autonomy_tick(event_state),
  )
}

///|
test "live autonomy metric counts compose runtime watcher and goal signals" {
  let goal = live_autonomy_watch_goal(
    id="watch-due",
    title="Due Watch",
    prompt="Track due topic",
    book_id="research-due",
    next_due_tick=10,
  )
  let disabled = @core.StandingGoal::new(
    id="watch-disabled",
    title="Disabled Watch",
    prompt="disabled",
    target_book_id=Some("research-disabled"),
    next_due_tick=10,
    enabled=false,
  )
  let update_record = live_autonomy_watcher_record(
    goal_id="watch-due",
    tick=10,
    book_id="research-due",
    decision=Update,
    next_due_tick=70,
  )
  let no_change_record = live_autonomy_watcher_record(
    goal_id="watch-due",
    tick=11,
    book_id="research-due",
    decision=NoChange,
    next_due_tick=71,
  )
  let metrics = live_autonomy_metric_counts(
    live_autonomy_empty_test_state(),
    [goal, disabled],
    [update_record, no_change_record],
    10,
  )
  assert_eq(metrics.active_workers, 0)
  assert_eq(metrics.review, 0)
  assert_eq(metrics.blocked, 0)
  assert_eq(metrics.accepted_updates, 1)
  assert_eq(metrics.no_change, 1)
  assert_eq(metrics.failed, 0)
  assert_eq(metrics.transient_infrastructure_debt, 0)
  assert_eq(metrics.enabled_standing_goals, 1)
  assert_eq(metrics.disabled_standing_goals, 1)
  assert_eq(metrics.due_goals, 1)
}
