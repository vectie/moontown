///|
pub fn live_autonomy_base_dir_for_snapshot(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
pub fn live_autonomy_path_for_snapshot(snapshot_path : String) -> String {
  "\{live_autonomy_base_dir_for_snapshot(snapshot_path)}/live-autonomy.json"
}

///|
pub fn town_journal_path_for_snapshot(snapshot_path : String) -> String {
  "\{live_autonomy_base_dir_for_snapshot(snapshot_path)}/town-journal.jsonl"
}

///|
pub fn live_digest_path_for_snapshot(snapshot_path : String) -> String {
  "\{live_autonomy_base_dir_for_snapshot(snapshot_path)}/live-digest.md"
}

///|
pub fn planbook_change_log_path_for_workspace(
  planbook_workspace_root : String,
) -> String {
  "\{planbook_workspace_root}/wiki/history/change-log.md"
}

///|
pub fn planbook_engineering_digest_path_for_workspace(
  planbook_workspace_root : String,
) -> String {
  "\{planbook_workspace_root}/wiki/history/daily-engineering-digest.md"
}

///|
pub fn live_autonomy_standing_goal_path_for_snapshot(
  snapshot_path : String,
) -> String {
  "\{live_autonomy_base_dir_for_snapshot(snapshot_path)}/standing-goals.json"
}
