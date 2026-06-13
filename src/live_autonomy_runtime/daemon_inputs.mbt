///|
async fn load_daemon_state(path : String) -> @scheduler.DaemonState {
  if !@fs.exists(path) {
    return @scheduler.DaemonState::new()
  }
  let text = @fs.read_file(path).text() catch {
    _ => return @scheduler.DaemonState::new()
  }
  let parsed = @json.parse(text) catch {
    _ => return @scheduler.DaemonState::new()
  }
  @json.from_json(parsed) catch {
    _ => @scheduler.DaemonState::new()
  }
}

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
      daemon.tick_sequence,
      latest_live_autonomy_journal_tick(snapshot_path),
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
fn latest_execution_task_tick(state : @core.TownState) -> Int {
  let mut tick = 0
  for execution in state.executions {
    let value = @core.tick_from_task_id(execution.task_id)
    if value > tick {
      tick = value
    }
  }
  tick
}

///|
fn latest_watcher_record_tick(records : Array[@core.WatcherRunRecord]) -> Int {
  let mut latest = 0
  for record in records {
    if record.tick > latest {
      latest = record.tick
    }
  }
  latest
}

///|
fn latest_standing_goal_tick(goals : Array[@core.StandingGoal]) -> Int {
  let mut latest = 0
  for goal in goals {
    match goal.last_run_tick {
      Some(last_run_tick) =>
        if last_run_tick > latest {
          latest = last_run_tick
        }
      None => ()
    }
  }
  latest
}
