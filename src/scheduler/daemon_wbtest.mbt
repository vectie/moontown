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
  assert_eq(actions[0].kind, standing_goal_due_action_kind())
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
  assert_true(
    actions.any(fn(action) { action.kind == standing_goal_due_action_kind() }),
  )
}

///|
test "daemon tick migrates persisted job list to current defaults" {
  let town = @core.empty_state(
    @core.TownConfig::new(id="town", name="Moontown"),
  )
  let report = @health.inspect_town(town)
  let old_jobs = [
    {
      id: supervision_job_id(),
      kind: supervision_job_kind(),
      interval_seconds: 30,
    },
    {
      id: standing_goal_job_id(),
      kind: standing_goal_job_kind(),
      interval_seconds: 30,
    },
    { id: health_job_id(), kind: health_job_kind(), interval_seconds: 60 },
    {
      id: projection_job_id(),
      kind: projection_job_kind(),
      interval_seconds: 60,
    },
  ]
  let old_daemon = DaemonState::new(jobs=old_jobs)
  let (daemon, _, _) = plan_daemon_tick(old_daemon, town, report)
  assert_true(daemon.jobs.any(fn(job) { job.id == civic_pattern_job_id() }))
  assert_true(daemon.jobs.any(fn(job) { job.id == civic_service_job_id() }))
  assert_true(
    daemon.jobs.any(fn(job) { job.id == book_quality_review_job_id() }),
  )
  assert_true(
    daemon.jobs.any(fn(job) { job.id == book_template_request_job_id() }),
  )
  assert_eq(daemon.jobs.length(), default_daemon_jobs().length())
}

///|
test "daemon tick drops deprecated civic salon job during migration" {
  let town = @core.empty_state(
    @core.TownConfig::new(id="town", name="Moontown"),
  )
  let report = @health.inspect_town(town)
  let old_jobs = [
    {
      id: legacy_civic_salon_job_id(),
      kind: legacy_civic_salon_job_kind(),
      interval_seconds: 30,
    },
    { id: health_job_id(), kind: health_job_kind(), interval_seconds: 60 },
  ]
  let old_daemon = DaemonState::new(jobs=old_jobs)
  let (daemon, _, _) = plan_daemon_tick(old_daemon, town, report)
  assert_true(
    !daemon.jobs.any(fn(job) { job.id == legacy_civic_salon_job_id() }),
  )
  assert_true(
    !daemon.jobs.any(fn(job) { job.kind == legacy_civic_salon_job_kind() }),
  )
  assert_true(daemon.jobs.any(fn(job) { job.id == civic_pattern_job_id() }))
  assert_eq(daemon.jobs.length(), default_daemon_jobs().length())
}

///|
test "scheduler classifies current and legacy civic communication jobs" {
  let current = {
    id: civic_pattern_job_id(),
    kind: civic_pattern_job_kind(),
    interval_seconds: 30,
  }
  let legacy = {
    id: legacy_civic_salon_job_id(),
    kind: legacy_civic_salon_job_kind(),
    interval_seconds: 30,
  }
  assert_true(scheduled_job_is_civic_pattern(current))
  assert_true(!scheduled_job_is_legacy_civic_salon(current))
  assert_true(scheduled_job_is_legacy_civic_salon(legacy))
  assert_true(scheduled_job_runs_civic_communication(current))
  assert_true(scheduled_job_runs_civic_communication(legacy))
}
