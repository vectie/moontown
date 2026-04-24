///|
pub struct TownRuntimeStatus {
  snapshot_path : String
  has_snapshot : Bool
  book_count : Int
  worker_count : Int
  task_count : Int
  execution_count : Int
  event_count : Int
  running_count : Int
  review_count : Int
  failed_count : Int
  stale_count : Int
  completed_count : Int
  daemon_actions : Array[@scheduler.SchedulerAction]
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub async fn inspect_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> TownRuntimeStatus {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => runtime_status_from_state(snapshot.town, snapshot_path)
    None =>
      {
        snapshot_path,
        has_snapshot: false,
        book_count: 0,
        worker_count: 0,
        task_count: 0,
        execution_count: 0,
        event_count: 0,
        running_count: 0,
        review_count: 0,
        failed_count: 0,
        stale_count: 0,
        completed_count: 0,
        daemon_actions: [],
        summary: "No saved town snapshot exists at \{snapshot_path}.",
      }
  }
}

///|
pub fn runtime_status_from_state(
  state : @core.TownState,
  snapshot_path : String,
) -> TownRuntimeStatus {
  let report = @health.inspect_town(state)
  let actions = @scheduler.plan_tick(state, report)
  let running = count_runtime_executions(state, [
    @core.TaskExecutionStatus::ProposalImported,
    @core.TaskExecutionStatus::RunConfirmed,
    @core.TaskExecutionStatus::Running,
    @core.TaskExecutionStatus::AwaitingPersistence,
  ])
  let review = count_runtime_executions(state, [
    @core.TaskExecutionStatus::ReviewQueued,
  ])
  let failed = count_runtime_executions(state, [
    @core.TaskExecutionStatus::Failed,
  ])
  let stale = count_runtime_executions(state, [@core.TaskExecutionStatus::Stale])
  let completed = count_runtime_executions(state, [
    @core.TaskExecutionStatus::Completed,
  ])
  {
    snapshot_path,
    has_snapshot: true,
    book_count: state.books.length(),
    worker_count: state.workers.length(),
    task_count: state.tasks.length(),
    execution_count: state.executions.length(),
    event_count: state.events.length(),
    running_count: running,
    review_count: review,
    failed_count: failed,
    stale_count: stale,
    completed_count: completed,
    daemon_actions: actions,
    summary: "books=\{state.books.length()} workers=\{state.workers.length()} tasks=\{state.tasks.length()} executions=\{state.executions.length()} running=\{running} review=\{review} failed=\{failed} stale=\{stale} planned_actions=\{actions.length()}",
  }
}

///|
fn count_runtime_executions(
  state : @core.TownState,
  statuses : Array[@core.TaskExecutionStatus],
) -> Int {
  let mut count = 0
  for execution in state.executions {
    for status in statuses {
      if execution.status == status {
        count += 1
        break
      }
    }
  }
  count
}

///|
pub async fn render_saved_town_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let status = inspect_saved_town(snapshot_path~)
  let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
  let builder = StringBuilder::new()
  builder.write_string("Moontown status\n")
  builder.write_string("\{status.summary}\n")
  if !status.has_snapshot {
    return builder.to_string()
  }
  builder.write_string("snapshot=\{status.snapshot_path}\n")
  builder.write_string(
    "daemon=\{daemon.daemon_id} tick=\{daemon.tick_sequence} lease=\{daemon.lease_owner} jobs=\{daemon.jobs.length()}\n",
  )
  builder.write_string(
    "planned daemon actions=\{status.daemon_actions.length()}\n",
  )
  for action in status.daemon_actions {
    builder.write_string("- \{action.kind}: \{action.detail}\n")
  }
  builder.to_string()
}

///|
pub async fn daemon_tick_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let snapshot = @storage.load_snapshot_file(snapshot_path)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let daemon_path = default_daemon_state_path(snapshot_path)
  let daemon = load_daemon_state(daemon_path)
  let mayor = demo_mayor()
  match snapshot {
    Some(saved) => {
      let state = saved.town
      run_supervision_cycle(state, mayor, catalog)
      persist_town_checkpoint(state, snapshot_path)
      let report = @health.inspect_town(state)
      let (next_daemon, tick, _) = @scheduler.plan_daemon_tick(
        daemon, state, report,
      )
      save_daemon_state(daemon_path, next_daemon)
      state.record_event(
        @core.TownEvent::new(
          id="event-daemon-\{tick.sequence}",
          kind="daemon",
          detail=tick.summary,
        ),
      )
      persist_town_checkpoint(state, snapshot_path)
      render_saved_town_status(snapshot_path~)
    }
    None => "No saved town snapshot exists at \{snapshot_path}."
  }
}

///|
fn default_daemon_state_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/daemon.json"
  } else {
    "\{base}/daemon.json"
  }
}

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
async fn save_daemon_state(
  path : String,
  daemon : @scheduler.DaemonState,
) -> Unit {
  write_text_file(path, daemon.to_json().stringify())
}
