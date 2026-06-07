///|
priv struct LiveAutonomyMetricCounts {
  active_workers : Int
  review : Int
  blocked : Int
  accepted_updates : Int
  no_change : Int
  failed : Int
  transient_infrastructure_debt : Int
  enabled_standing_goals : Int
  disabled_standing_goals : Int
  due_goals : Int
}

///|
priv struct LiveAutonomyWatcherDecisionCounts {
  accepted_updates : Int
  no_change : Int
}

///|
fn live_autonomy_metric_counts(
  state : @core.TownState,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
  tick : Int,
) -> LiveAutonomyMetricCounts {
  let health_report = @health.inspect_town(state)
  let goal_counts = standing_goal_counts(standing_goals, tick + 1)
  let watcher_counts = live_autonomy_watcher_decision_counts(watcher_records)
  {
    active_workers: live_autonomy_active_worker_count(state),
    review: live_autonomy_review_count(state),
    blocked: health_report.anomalies.length(),
    accepted_updates: watcher_counts.accepted_updates,
    no_change: watcher_counts.no_change,
    failed: count_health_anomalies_by_title(health_report, "execution-failed"),
    transient_infrastructure_debt: live_autonomy_transient_infrastructure_debt_count(
      state,
    ),
    enabled_standing_goals: goal_counts.enabled,
    disabled_standing_goals: goal_counts.disabled,
    due_goals: goal_counts.due,
  }
}

///|
fn live_autonomy_active_worker_count(state : @core.TownState) -> Int {
  count_live_activity(state)
}

///|
fn live_autonomy_review_count(state : @core.TownState) -> Int {
  count_live_executions(state, review_execution_statuses())
}

///|
fn live_autonomy_transient_infrastructure_debt_count(
  state : @core.TownState,
) -> Int {
  count_transient_infrastructure_debt(state)
}

///|
fn live_autonomy_watcher_decision_counts(
  watcher_records : Array[@core.WatcherRunRecord],
) -> LiveAutonomyWatcherDecisionCounts {
  {
    accepted_updates: count_watcher_decisions(
      watcher_records,
      @core.WatcherDecisionKind::Update,
    ),
    no_change: count_watcher_decisions(
      watcher_records,
      @core.WatcherDecisionKind::NoChange,
    ),
  }
}
