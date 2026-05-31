///|
test "scheduler plans due standing goals" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Research OPC.",
    target_book_id=Some("research-opc"),
    cadence_ticks=6,
    next_due_tick=1,
  )
  let actions = plan_standing_goal_actions([goal], 1)
  assert_eq(actions.length(), 1)
  assert_eq(actions[0].kind, "standing-goal-due")
  assert_true(actions[0].detail.contains("research-opc"))
}

///|
test "daemon tick records active due goal ids" {
  let town = @core.empty_state(
    @core.TownConfig::new(id="town", name="Moontown"),
  )
  let report = @health.inspect_town(town)
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Research OPC.",
    target_book_id=Some("research-opc"),
    next_due_tick=1,
  )
  let (daemon, tick, actions) = plan_daemon_tick(
    DaemonState::new(),
    town,
    report,
    standing_goals=[goal],
  )
  assert_eq(tick.sequence, 1)
  assert_true(daemon.active_goal_ids == ["watch-opc-news"])
  assert_true(actions.any(fn(action) { action.kind == "standing-goal-due" }))
}

///|
test "daemon tick migrates persisted job list to current defaults" {
  let town = @core.empty_state(
    @core.TownConfig::new(id="town", name="Moontown"),
  )
  let report = @health.inspect_town(town)
  let old_jobs = [
    { id: "supervise-live-runs", kind: "supervision", interval_seconds: 30 },
    {
      id: "dispatch-standing-goals",
      kind: "standing-goal",
      interval_seconds: 30,
    },
    { id: "refresh-health", kind: "health", interval_seconds: 60 },
    { id: "project-ui-state", kind: "projection", interval_seconds: 60 },
  ]
  let old_daemon = DaemonState::new(jobs=old_jobs)
  let (daemon, _, _) = plan_daemon_tick(old_daemon, town, report)
  assert_true(daemon.jobs.any(fn(job) { job.id == "run-civic-patterns" }))
  assert_eq(daemon.jobs.length(), default_daemon_jobs().length())
}
