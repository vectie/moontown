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
fn default_daemon_state_path(snapshot_path : String) -> String {
  @daemon_runtime_policy.daemon_state_path_for_snapshot(snapshot_path)
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
    let value = tick_from_task_id(execution.task_id)
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

///|
fn tick_from_task_id(task_id : String) -> Int {
  match tick_marker_index(task_id) {
    Some(index) => trailing_int(task_id[index + 5:].to_owned())
    None => 0
  }
}

///|
fn tick_marker_index(task_id : String) -> Int? {
  let marker = "tick-"
  let limit = task_id.length() - marker.length()
  if limit < 0 {
    return None
  }
  let mut found : Int? = None
  for index in 0..<=limit {
    if task_id[index:index + marker.length()].to_owned() == marker {
      found = Some(index)
    }
  }
  found
}

///|
fn trailing_int(text : String) -> Int {
  let mut value = 0
  let mut seen = false
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return value
    }
  }
  value
}
