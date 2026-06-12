///|
async fn write_live_autonomy_digest(
  path : String,
  state : @core.TownState,
  spine : LiveAutonomySpine,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> Unit {
  @support.write_text_file(
    path,
    render_live_autonomy_digest(state, spine, standing_goals, watcher_records),
  )
}
