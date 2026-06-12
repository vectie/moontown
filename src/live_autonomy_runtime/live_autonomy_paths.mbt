///|
pub fn default_live_autonomy_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @live_autonomy_policy.live_autonomy_path_for_snapshot(snapshot_path)
}

///|
pub fn default_town_journal_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @live_autonomy_policy.town_journal_path_for_snapshot(snapshot_path)
}

///|
pub fn default_live_digest_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @live_autonomy_policy.live_digest_path_for_snapshot(snapshot_path)
}

///|
fn live_autonomy_planbook_change_log_path() -> String {
  @live_autonomy_policy.planbook_change_log_path_for_workspace(
    default_planbook_workspace_root(),
  )
}

///|
fn live_autonomy_planbook_engineering_digest_path() -> String {
  @live_autonomy_policy.planbook_engineering_digest_path_for_workspace(
    default_planbook_workspace_root(),
  )
}

///|
fn standing_goal_tick_seconds() -> Int {
  30
}

///|
fn live_autonomy_standing_goal_path(snapshot_path : String) -> String {
  @live_autonomy_policy.live_autonomy_standing_goal_path_for_snapshot(
    snapshot_path,
  )
}
