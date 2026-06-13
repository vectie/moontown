///|
priv struct LiveAutonomyRuntimeInputs {
  standing_goals : Array[@core.StandingGoal]
  watcher_records : Array[@core.WatcherRunRecord]
  daemon_tick : Int
}

///|
async fn load_live_autonomy_runtime_inputs(
  snapshot_path : String,
  state : @core.TownState,
) -> LiveAutonomyRuntimeInputs {
  let loaded = load_live_autonomy_watch_inputs(snapshot_path)
  let daemon = load_daemon_state(
    @daemon_runtime_policy.daemon_state_path_for_snapshot(snapshot_path),
  )
  let daemon_tick = effective_daemon_tick(
    snapshot_path,
    daemon,
    state,
    loaded.standing_goals,
    loaded.watcher_records,
  )
  {
    standing_goals: loaded.standing_goals,
    watcher_records: loaded.watcher_records,
    daemon_tick,
  }
}

///|
async fn load_live_autonomy_runtime_inputs_without_snapshot(
  snapshot_path : String,
) -> LiveAutonomyRuntimeInputs {
  let loaded = load_live_autonomy_watch_inputs(snapshot_path)
  let daemon = load_daemon_state(
    @daemon_runtime_policy.daemon_state_path_for_snapshot(snapshot_path),
  )
  {
    standing_goals: loaded.standing_goals,
    watcher_records: loaded.watcher_records,
    daemon_tick: daemon.tick_sequence,
  }
}

///|
priv struct LiveAutonomyWatchInputs {
  standing_goals : Array[@core.StandingGoal]
  watcher_records : Array[@core.WatcherRunRecord]
}

///|
async fn load_live_autonomy_watch_inputs(
  snapshot_path : String,
) -> LiveAutonomyWatchInputs {
  let standing_goals = @storage.load_or_create_standing_goals(
    path=live_autonomy_standing_goal_path(snapshot_path),
  )
  let watcher_records = load_live_autonomy_watcher_records(
    snapshot_path, standing_goals,
  )
  { standing_goals, watcher_records }
}
