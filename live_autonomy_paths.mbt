///|
pub fn default_live_autonomy_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/live-autonomy.json"
}

///|
pub fn default_town_journal_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/town-journal.jsonl"
}

///|
pub fn default_live_digest_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/live-digest.md"
}

///|
fn live_autonomy_planbook_change_log_path() -> String {
  "\{default_planbook_workspace_root()}/wiki/history/change-log.md"
}

///|
fn live_autonomy_planbook_engineering_digest_path() -> String {
  "\{default_planbook_workspace_root()}/wiki/history/daily-engineering-digest.md"
}

///|
fn standing_goal_tick_seconds() -> Int {
  30
}

///|
fn live_autonomy_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
fn live_autonomy_standing_goal_path(snapshot_path : String) -> String {
  "\{live_autonomy_base_dir(snapshot_path)}/standing-goals.json"
}
