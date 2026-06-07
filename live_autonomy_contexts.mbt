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
    watcher_records,
    transient_infrastructure_debt: metrics.transient_infrastructure_debt,
  }
}
