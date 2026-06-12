///|
pub fn legacy_tick_domain_stale_standing_watch(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  execution.status == @core.TaskExecutionStatus::Stale &&
  execution.run_id is None &&
  execution.output_contract == "standing-watch-live-snapshot" &&
  execution.summary.contains("missed its heartbeat window") &&
  @core.tick_from_task_id(execution.task_id) > execution.stale_after_tick
}

///|
pub fn legacy_review_queued_retry_accounting_standing_watch(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  if execution.status != @core.TaskExecutionStatus::ReviewQueued {
    return false
  }
  if !standing_watch_infrastructure_failure_summary(execution.summary) {
    return false
  }
  let task_tick = @core.tick_from_task_id(execution.task_id)
  let decision = standing_watch_recovery_decision_from_execution(execution)
  task_tick > execution.stale_after_tick ||
  decision == @core.WatcherDecisionKind::Deferred ||
  (
    decision == @core.WatcherDecisionKind::Failed &&
    standing_watch_execution_has_zero_material_delta(execution)
  )
}
