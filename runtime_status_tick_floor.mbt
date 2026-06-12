///|
async fn effective_daemon_tick(
  snapshot_path : String,
  daemon : @scheduler.DaemonState,
  state : @core.TownState,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> Int {
  @support.max_int(
    @support.max_int(
      @support.max_int(
        daemon.tick_sequence,
        @daemon_runtime.latest_daemon_log_sequence(
          @daemon_runtime.default_daemon_log_path(snapshot_path~),
        ),
      ),
      @live_autonomy_runtime.latest_live_autonomy_journal_tick(snapshot_path),
    ),
    @support.max_int(
      @support.max_int(
        latest_standing_goal_tick(standing_goals),
        latest_watcher_record_tick(watcher_records),
      ),
      latest_execution_task_tick(state),
    ),
  )
}

///|
async fn daemon_tick_floor(
  snapshot_path : String,
  log_path : String,
  daemon : @scheduler.DaemonState,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
  state : @core.TownState,
) -> Int {
  let mut floor = daemon.tick_sequence
  for
    candidate in [
      @daemon_runtime.latest_daemon_log_sequence(log_path),
      @live_autonomy_runtime.latest_live_autonomy_journal_tick(snapshot_path),
      latest_standing_goal_tick(standing_goals),
      latest_watcher_record_tick(watcher_records),
      latest_execution_task_tick(state),
    ] {
    if candidate > floor {
      floor = candidate
    }
  }
  floor
}

///|
fn daemon_rebased_to_tick_floor(
  daemon : @scheduler.DaemonState,
  tick_floor : Int,
) -> @scheduler.DaemonState {
  if tick_floor <= daemon.tick_sequence {
    return daemon
  }
  @scheduler.DaemonState::new(
    daemon_id=daemon.daemon_id,
    lease_owner=daemon.lease_owner,
    tick_sequence=tick_floor,
    last_heartbeat_event_count=daemon.last_heartbeat_event_count,
    active_goal_ids=daemon.active_goal_ids,
    jobs=daemon.jobs,
  )
}

///|
fn latest_execution_task_tick(state : @core.TownState) -> Int {
  let mut tick = 0
  for execution in state.executions {
    let value = tick_from_task_id(execution.task_id)
    if value > tick {
      tick = value
    }
  }
  tick
}

///|
fn tick_from_task_id(task_id : String) -> Int {
  if !task_id.contains("-tick-") {
    return 0
  }
  let parts = task_id.split("-tick-").to_array()
  match parts.get(parts.length() - 1) {
    Some(suffix) =>
      match first_non_negative_int(suffix.to_owned()) {
        Some(value) => value
        None => 0
      }
    None => 0
  }
}
