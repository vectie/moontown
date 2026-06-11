///|
fn standing_watch_policy_goal(threshold : Int) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id="watch-policy",
    title="Watch policy",
    prompt="watch policy",
    target_book_id=Some("research-opc"),
    quality_threshold=threshold,
  )
}

///|
fn standing_watch_policy_execution(
  summary : String,
  status? : @core.TaskExecutionStatus = @core.TaskExecutionStatus::Completed,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id="watch-policy-task",
    book_id="research-opc",
    packet_id="watch-policy-packet",
    packet_path="watch-policy-packet.json",
    status~,
    summary~,
    output_contract="standing-watch",
  )
}

///|
test "standing watch keeper closure accepts no-change regardless of threshold" {
  let goal = standing_watch_policy_goal(90)
  let execution = standing_watch_policy_execution(
    "standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0",
  )
  assert_true(
    standing_watch_auto_triage_allowed(
      goal,
      execution,
      @core.WatcherDecisionKind::NoChange,
    ),
  )
  assert_true(
    standing_watch_recovery_allowed(
      goal,
      execution,
      @core.WatcherDecisionKind::NoChange,
    ),
  )
}

///|
test "standing watch keeper closure accepts updates only above threshold" {
  let goal = standing_watch_policy_goal(80)
  let weak_update = standing_watch_policy_execution(
    "standing_goal_decision: update\ndelta_score: 79\nnew_source_count: 1",
  )
  let strong_update = standing_watch_policy_execution(
    "standing_goal_decision: update\ndelta_score: 80\nnew_source_count: 1",
  )
  assert_true(
    !standing_watch_auto_triage_allowed(
      goal,
      weak_update,
      @core.WatcherDecisionKind::Update,
    ),
  )
  assert_true(
    standing_watch_auto_triage_allowed(
      goal,
      strong_update,
      @core.WatcherDecisionKind::Update,
    ),
  )
  assert_true(
    !standing_watch_recovery_allowed(
      goal,
      weak_update,
      @core.WatcherDecisionKind::Update,
    ),
  )
  assert_true(
    standing_watch_recovery_allowed(
      goal,
      strong_update,
      @core.WatcherDecisionKind::Update,
    ),
  )
}

///|
test "standing watch keeper closure rejects non-terminal decisions" {
  let goal = standing_watch_policy_goal(10)
  let execution = standing_watch_policy_execution(
    "standing_goal_decision: needs_review\ndelta_score: 100\nnew_source_count: 2",
  )
  assert_true(
    !standing_watch_auto_triage_allowed(
      goal,
      execution,
      @core.WatcherDecisionKind::NeedsReview,
    ),
  )
  assert_true(
    !standing_watch_recovery_allowed(
      goal,
      execution,
      @core.WatcherDecisionKind::Failed,
    ),
  )
}

///|
test "standing watch policy summaries use explicit keeper metadata" {
  let goal = standing_watch_policy_goal(75)
  let execution = standing_watch_policy_execution(
    "standing_goal_decision: no_change",
  )
  let triage_summary = standing_watch_auto_triage_summary(
    goal,
    execution,
    @core.WatcherDecisionKind::NoChange,
  )
  let recovery_summary = standing_watch_recovery_summary(
    goal,
    execution,
    @core.WatcherDecisionKind::NoChange,
  )
  assert_true(triage_summary.contains("keeper_auto_triage: accepted"))
  assert_true(triage_summary.contains("auto_triage_threshold: 75"))
  assert_true(triage_summary.contains("auto_triage_decision: NoChange"))
  assert_true(triage_summary.contains("keeper-level autonomous closure"))
  assert_true(recovery_summary.contains("keeper_auto_recovery: accepted"))
  assert_true(recovery_summary.contains("auto_recovery_threshold: 75"))
  assert_true(recovery_summary.contains("auto_recovery_decision: NoChange"))
  assert_true(recovery_summary.contains("without operator intervention"))
}

///|
test "standing watch recovery decision trusts terminal marker over failed status" {
  let execution = standing_watch_policy_execution(
    "MoonClaw transport failed\nstanding_goal_decision: no_change\ndelta_score: 0",
    status=@core.TaskExecutionStatus::Failed,
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::Failed,
  )
  assert_eq(
    standing_watch_recovery_decision_from_execution(execution),
    @core.WatcherDecisionKind::NoChange,
  )
}
