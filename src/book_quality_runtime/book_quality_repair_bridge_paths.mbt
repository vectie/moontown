///|
async fn book_quality_current_daemon_tick(snapshot_path : String) -> Int {
  let path = @daemon_runtime_policy.daemon_state_path_for_snapshot(
    snapshot_path,
  )
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
fn book_quality_standing_goal_path(snapshot_path : String) -> String {
  @daemon_runtime_policy.daemon_standing_goal_path_for_snapshot(
    snapshot_path,
    @storage.default_standing_goal_path(),
  )
}
