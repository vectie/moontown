///|
async fn terminal_watcher_record_for_execution(
  goal_id : String,
  ledger_dir : String,
  execution : @core.TaskExecutionRecord,
) -> @core.WatcherRunRecord? {
  let records = @storage.load_watcher_run_records(goal_id, dir=ledger_dir)
  let mut found : @core.WatcherRunRecord? = None
  for record in records {
    if record.task_id == Some(execution.task_id) &&
      watcher_record_run_matches_execution(record, execution) &&
      record.decision != @core.WatcherDecisionKind::Deferred {
      found = Some(record)
    }
  }
  found
}

///|
fn watcher_record_run_matches_execution(
  record : @core.WatcherRunRecord,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  match execution.run_id {
    Some(run_id) => record.run_id == Some(run_id)
    None => true
  }
}

///|
fn task_status_for_terminal_watcher_decision(
  decision : @core.WatcherDecisionKind,
) -> @core.TaskExecutionStatus {
  match decision {
    @core.WatcherDecisionKind::NeedsReview =>
      @core.TaskExecutionStatus::ReviewQueued
    @core.WatcherDecisionKind::Failed => @core.TaskExecutionStatus::Failed
    _ => @core.TaskExecutionStatus::Completed
  }
}
