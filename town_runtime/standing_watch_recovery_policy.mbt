///|
fn standing_watch_auto_triage_allowed(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  standing_watch_keeper_closure_allowed(goal, execution, decision)
}

///|
fn standing_watch_auto_triage_summary(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> String {
  standing_watch_keeper_acceptance_summary(
    execution,
    marker="keeper_auto_triage",
    decision_label="auto_triage_decision",
    threshold_label="auto_triage_threshold",
    reason_label="auto_triage_reason",
    decision~,
    threshold=goal.quality_threshold,
    reason=standing_watch_auto_triage_reason(),
  )
}

///|
fn standing_watch_recovery_allowed(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  standing_watch_keeper_closure_allowed(goal, execution, decision)
}

///|
fn standing_watch_recovery_decision_from_execution(
  execution : @core.TaskExecutionRecord,
) -> @core.WatcherDecisionKind {
  @standing_watch_policy.standing_watch_marker_decision(
    execution.summary.to_lower(),
  ).unwrap_or(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
  )
}

///|
fn standing_watch_recovery_summary(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> String {
  standing_watch_keeper_acceptance_summary(
    execution,
    marker="keeper_auto_recovery",
    decision_label="auto_recovery_decision",
    threshold_label="auto_recovery_threshold",
    reason_label="auto_recovery_reason",
    decision~,
    threshold=goal.quality_threshold,
    reason=standing_watch_recovery_reason(),
  )
}

///|
fn standing_watch_keeper_closure_allowed(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
  decision : @core.WatcherDecisionKind,
) -> Bool {
  match decision {
    @core.WatcherDecisionKind::NoChange => true
    @core.WatcherDecisionKind::Update =>
      standing_watch_delta_meets_threshold(goal, execution)
    _ => false
  }
}

///|
fn standing_watch_delta_meets_threshold(
  goal : @core.StandingGoal,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  @standing_watch_policy.standing_watch_delta_score(execution) >=
  goal.quality_threshold
}

///|
fn standing_watch_keeper_acceptance_summary(
  execution : @core.TaskExecutionRecord,
  marker~ : String,
  decision_label~ : String,
  threshold_label~ : String,
  reason_label~ : String,
  decision~ : @core.WatcherDecisionKind,
  threshold~ : Int,
  reason~ : String,
) -> String {
  "\{execution.summary}\n\{marker}: accepted\n\{decision_label}: \{decision.to_string()}\n\{threshold_label}: \{threshold}\n\{reason_label}: \{reason}"
}

///|
fn standing_watch_auto_triage_reason() -> String {
  "MoonBook standing-watch marker was sufficient for keeper-level autonomous closure."
}

///|
fn standing_watch_recovery_reason() -> String {
  "Failed transport/index status was superseded by a terminal MoonBook standing-watch marker, so mayor closed it without operator intervention."
}
