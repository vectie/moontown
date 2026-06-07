///|
async fn persist_live_autonomy_spine(
  snapshot_path : String,
  state : @core.TownState,
  spine : LiveAutonomySpine,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> Unit {
  write_text_file(
    default_live_autonomy_path(snapshot_path~),
    spine.to_json().stringify(indent=2),
  )
  append_live_autonomy_journal(default_town_journal_path(snapshot_path~), spine)
  write_live_autonomy_digest(
    default_live_digest_path(snapshot_path~),
    state,
    spine,
    standing_goals,
    watcher_records,
  )
}
