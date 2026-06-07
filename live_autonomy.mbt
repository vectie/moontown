///|
pub async fn write_live_autonomy_spine(
  state : @core.TownState,
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goals? : Array[@core.StandingGoal] = [],
  watcher_records? : Array[@core.WatcherRunRecord] = [],
  tick_summary? : String = "",
  daemon_tick? : Int? = None,
) -> LiveAutonomySpine {
  let metadata = live_autonomy_write_metadata(state, snapshot_path, daemon_tick)
  let spine = build_live_autonomy_spine({
    state,
    snapshot_path,
    standing_goals,
    watcher_records,
    tick_summary,
    daemon_tick: Some(metadata.tick),
    planbook_open: metadata.planbook_open,
    planbook_repair_active: metadata.planbook_repair_active,
    planbook_change_log_path: metadata.planbook_change_log_path,
    planbook_engineering_digest_path: metadata.planbook_engineering_digest_path,
    latest_change_summary: metadata.latest_change_summary,
    book_template_request_status: metadata.book_template_request_status,
    prior_stable_waiting_observation_streak: metadata.prior_stable_waiting_observation_streak,
  })
  persist_live_autonomy_spine(
    snapshot_path, state, spine, standing_goals, watcher_records,
  )
  spine
}
