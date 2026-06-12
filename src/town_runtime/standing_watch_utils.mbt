///|
async fn append_standing_watch_record(
  goal_id : String,
  ledger_dir : String,
  record : @core.WatcherRunRecord,
) -> Unit {
  @storage.append_watcher_run_record_file(
    @storage.watcher_ledger_path(goal_id, dir=ledger_dir),
    record,
  )
}

///|
fn record_standing_watch_event(
  state : @core.TownState,
  record : @core.WatcherRunRecord,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-watch-\{record.tick}-\{record.goal_id}",
      kind="standing-watch",
      detail="Standing watch \{record.goal_id} -> \{record.decision.to_string()} for \{record.target_book_id}; next_due_tick=\{record.next_due_tick}; \{record.detail}",
      related_book_id=Some(record.target_book_id),
      related_task_id=record.task_id,
      related_run_id=record.run_id,
    ),
  )
}

///|
fn watcher_ledger_dir_for_snapshot(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    @storage.default_watcher_ledger_dir()
  } else {
    "\{base}/watchers"
  }
}
