///|
pub fn default_watcher_ledger_dir() -> String {
  ".moontown/watchers"
}

///|
pub fn watcher_ledger_path(
  goal_id : String,
  dir? : String = default_watcher_ledger_dir(),
) -> String {
  "\{dir}/\{safe_watcher_goal_id(goal_id)}.jsonl"
}

///|
pub fn watcher_ledger_dir_for_snapshot(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    default_watcher_ledger_dir()
  } else {
    "\{base}/watchers"
  }
}

///|
pub async fn append_watcher_run_record(
  goal_id : String,
  record : @core.WatcherRunRecord,
  dir? : String = default_watcher_ledger_dir(),
) -> Unit {
  append_watcher_run_record_file(watcher_ledger_path(goal_id, dir~), record)
}

///|
pub async fn append_watcher_run_record_file(
  path : String,
  record : @core.WatcherRunRecord,
) -> Unit {
  ensure_parent_directory(path)
  let previous = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  let prefix = if previous.is_empty() || previous.has_suffix("\n") {
    previous
  } else {
    "\{previous}\n"
  }
  let line = record.to_json().stringify()
  @fs.write_file(
    path,
    @encoding/utf8.encode("\{prefix}\{line}\n"),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_watcher_run_records_file(
  path : String,
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  if !@fs.exists(path) {
    return records
  }
  let text = @fs.read_file(path).text() catch { _ => return records }
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch { _ => continue }
    let record : @core.WatcherRunRecord = @json.from_json(parsed) catch {
      _ => continue
    }
    records.push(record)
  }
  records
}

///|
pub async fn load_watcher_run_records(
  goal_id : String,
  dir? : String = default_watcher_ledger_dir(),
) -> Array[@core.WatcherRunRecord] {
  load_watcher_run_records_file(watcher_ledger_path(goal_id, dir~))
}

///|
pub fn consecutive_no_change_count(
  records : Array[@core.WatcherRunRecord],
) -> Int {
  let mut count = 0
  for index = records.length(); index > 0; index = index - 1 {
    if records[index - 1].decision == @core.WatcherDecisionKind::NoChange {
      count += 1
    } else {
      break
    }
  }
  count
}
