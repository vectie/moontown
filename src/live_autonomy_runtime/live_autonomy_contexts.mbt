///|
fn live_autonomy_blocker_context(
  metrics : LiveAutonomyMetricCounts,
  planbook_open : Int,
  planbook_repair_active : Int,
  pending_book_template_requests : Int,
  failed_book_template_requests : Int,
) -> LiveAutonomyBlockerContext {
  {
    active_workers: metrics.active_workers,
    review: metrics.review,
    blocked: metrics.blocked,
    failed: metrics.failed,
    due_goals: metrics.due_goals,
    planbook_open,
    planbook_repair_active,
    pending_book_template_requests,
    failed_book_template_requests,
  }
}

///|
fn live_autonomy_action_context(
  metrics : LiveAutonomyMetricCounts,
  watcher_records : Array[@core.WatcherRunRecord],
  planbook_open : Int,
  planbook_repair_active : Int,
  pending_book_template_requests : Int,
  failed_book_template_requests : Int,
) -> LiveAutonomyActionContext {
  {
    blockers: live_autonomy_blocker_context(
      metrics, planbook_open, planbook_repair_active, pending_book_template_requests,
      failed_book_template_requests,
    ),
    latest_watcher_decision: live_autonomy_latest_watcher_decision(
      watcher_records,
    ),
    transient_infrastructure_debt: metrics.transient_infrastructure_debt,
  }
}

///|
fn live_autonomy_latest_watcher_decision(
  watcher_records : Array[@core.WatcherRunRecord],
) -> @core.WatcherDecisionKind? {
  match latest_watcher_record(watcher_records) {
    Some(record) =>
      Some(@standing_watch_policy.watcher_record_effective_decision(record))
    None => None
  }
}
