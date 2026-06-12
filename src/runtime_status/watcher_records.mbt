///|
async fn load_watcher_records_for_goals(
  snapshot_path : String,
  goals : Array[@core.StandingGoal],
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  for goal in goals {
    for record in @storage.load_watcher_run_records(goal.id, dir=ledger_dir) {
      records.push(record)
    }
  }
  records
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
