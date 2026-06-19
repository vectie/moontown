///|
test "live autonomy summary metrics are grouped by subsystem" {
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
  let context = LiveAutonomySummaryContext::{
    tick: 42,
    metrics,
    waiting: {
      stable_waiting: true,
      stable_waiting_observation_streak: 11,
      stable_waiting_blockers: [],
    },
    planbook_open: 12,
    template_request_count: 13,
    pending_template_count: 14,
  }
  let summary = live_autonomy_summary_line("daemon tick", context)
  assert_eq(
    summary, "daemon tick; tick=42 active=1 review=2 blocked=3 stable_waiting=true stable_waiting_observation_streak=11 accepted_updates=4 no_change=5 transient_infra_debt=7 enabled_goals=8 disabled_goals=9 planbook_open=12 template_requests=13 pending_templates=14",
  )
}

///|
test "live autonomy stable waiting streak advances only while stable" {
  assert_eq(
    @live_autonomy_policy.next_live_autonomy_stable_waiting_observation_streak(
      true, 0,
    ),
    1,
  )
  assert_eq(
    @live_autonomy_policy.next_live_autonomy_stable_waiting_observation_streak(
      true, 4,
    ),
    5,
  )
  assert_eq(
    @live_autonomy_policy.next_live_autonomy_stable_waiting_observation_streak(
      false, 4,
    ),
    0,
  )
}

///|
test "live autonomy waiting state owns blocker and streak rules" {
  let metrics = LiveAutonomyMetricCounts::{
    active_workers: 0,
    review: 0,
    blocked: 0,
    accepted_updates: 0,
    no_change: 0,
    failed: 0,
    transient_infrastructure_debt: 0,
    enabled_standing_goals: 1,
    disabled_standing_goals: 0,
    due_goals: 0,
  }
  let stable = @live_autonomy_policy.live_autonomy_waiting_state(
    live_autonomy_blocker_context(metrics, 0, 0, 0, 0),
    2,
  )
  assert_true(stable.stable_waiting)
  assert_eq(stable.stable_waiting_observation_streak, 3)
  assert_true(stable.stable_waiting_blockers.is_empty())
  let blocked = @live_autonomy_policy.live_autonomy_waiting_state(
    live_autonomy_blocker_context(metrics, 1, 0, 0, 0),
    2,
  )
  assert_false(blocked.stable_waiting)
  assert_eq(blocked.stable_waiting_observation_streak, 0)
  assert_true(blocked.stable_waiting_blockers.contains("PlanBook open gaps: 1"))
}
