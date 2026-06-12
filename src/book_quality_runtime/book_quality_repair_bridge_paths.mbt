///|
async fn book_quality_current_daemon_tick(snapshot_path : String) -> Int {
  let path = book_quality_daemon_state_path(snapshot_path)
  if !@fs.exists(path) {
    return 0
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch { _ => return 0 }
  match parsed {
    Object(object) =>
      match object.get("tick_sequence") {
        Some(Number(value, ..)) => value.to_int()
        _ => 0
      }
    _ => 0
  }
}

///|
fn book_quality_daemon_state_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/daemon.json"
  } else {
    "\{base}/daemon.json"
  }
}

///|
fn book_quality_standing_goal_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    @storage.default_standing_goal_path()
  } else {
    "\{base}/standing-goals.json"
  }
}
