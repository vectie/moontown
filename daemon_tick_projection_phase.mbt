///|
async fn run_daemon_projection_phase(
  state : @core.TownState,
  daemon : @scheduler.DaemonState,
  paths : DaemonTickPaths,
  snapshot_path : String,
  tick_sequence : Int,
  standing_goals : Array[@core.StandingGoal],
  planbook_phase : DaemonPlanbookPhaseResult,
) -> String {
  let watcher_records = load_watcher_records_for_goals(
    snapshot_path, standing_goals,
  )
  append_daemon_tick_phase_log(paths.log_path, "projection", tick_sequence)
  @visual_projection.persist_visual_projection(state, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  let report = @health.inspect_town(state)
  let (next_daemon, tick, _) = @scheduler.plan_daemon_tick(
    daemon,
    state,
    report,
    standing_goals~,
  )
  @daemon_runtime.save_daemon_state(paths.daemon_path, next_daemon)
  append_daemon_tick_phase_log(paths.log_path, "done", tick_sequence)
  record_daemon_tick_events(
    state,
    tick,
    planbook_phase.planbook_summary,
    planbook_phase.repair_summary,
  )
  ignore(
    @live_autonomy_runtime.write_live_autonomy_spine(
      state,
      snapshot_path~,
      standing_goals~,
      watcher_records~,
      tick_summary=tick.summary,
      daemon_tick=Some(tick.sequence),
    ),
  )
  @visual_projection.persist_visual_projection(state, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  @runtime_status.render_saved_town_status(snapshot_path~)
}

///|
fn record_daemon_tick_events(
  state : @core.TownState,
  tick : @scheduler.SchedulerTick,
  planbook_summary : String,
  planbook_repair_summary : String,
) -> Unit {
  record_daemon_tick_event(state, tick.sequence, "daemon", tick.summary)
  record_daemon_tick_event(state, tick.sequence, "planbook", planbook_summary)
  record_daemon_tick_event(
    state,
    tick.sequence,
    "planbook-repair",
    planbook_repair_summary,
  )
}

///|
fn record_daemon_tick_event(
  state : @core.TownState,
  sequence : Int,
  kind : String,
  detail : String,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(id="event-\{kind}-\{sequence}", kind~, detail~),
  )
}
