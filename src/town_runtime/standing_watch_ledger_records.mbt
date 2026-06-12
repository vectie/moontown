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
      @standing_watch_policy.watcher_record_matches_execution(record, execution) &&
      record.decision != @core.WatcherDecisionKind::Deferred {
      found = Some(record)
    }
  }
  found
}
