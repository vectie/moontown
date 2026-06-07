///|
fn render_live_autonomy_digest(
  state : @core.TownState,
  spine : LiveAutonomySpine,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> String {
  let builder = StringBuilder::new()
  write_live_autonomy_digest_header(builder, spine)
  write_live_autonomy_digest_stable_blockers(builder, spine)
  write_live_autonomy_digest_standing_watches(
    builder, spine, standing_goals, watcher_records,
  )
  write_live_autonomy_digest_tail(builder, state, spine)
  builder.to_string()
}
