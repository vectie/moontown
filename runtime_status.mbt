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
  standing_goal_count : Int
  due_standing_goal_count : Int
  daemon_actions : Array[@scheduler.SchedulerAction]
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub async fn inspect_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> TownRuntimeStatus {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
      let goals = @storage.load_or_create_standing_goals(
        path=default_standing_goal_state_path(snapshot_path),
      )
      runtime_status_from_state(
        snapshot.town,
        snapshot_path,
        standing_goals=goals,
        daemon_tick=daemon.tick_sequence,
      )
    }
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
        standing_goal_count: 0,
        due_standing_goal_count: 0,
        daemon_actions: [],
        summary: "No saved town snapshot exists at \{snapshot_path}.",
      }
  }
}

///|
pub fn runtime_status_from_state(
  state : @core.TownState,
  snapshot_path : String,
  standing_goals? : Array[@core.StandingGoal] = [],
  daemon_tick? : Int = 0,
) -> TownRuntimeStatus {
  let report = @health.inspect_town(state)
  let actions = @scheduler.plan_tick(state, report)
  let next_tick = daemon_tick + 1
  let due_goals = @scheduler.due_standing_goals(standing_goals, next_tick)
  for action in @scheduler.plan_standing_goal_actions(standing_goals, next_tick) {
    actions.push(action)
  }
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
    standing_goal_count: standing_goals.length(),
    due_standing_goal_count: due_goals.length(),
    daemon_actions: actions,
    summary: "books=\{state.books.length()} workers=\{state.workers.length()} tasks=\{state.tasks.length()} executions=\{state.executions.length()} running=\{running} review=\{review} failed=\{failed} stale=\{stale} standing_goals=\{standing_goals.length()} due_goals=\{due_goals.length()} planned_actions=\{actions.length()}",
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
    "standing_goals=\{status.standing_goal_count} due_next_tick=\{status.due_standing_goal_count}\n",
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
  let goal_path = default_standing_goal_state_path(snapshot_path)
  let standing_goals = @storage.load_or_create_standing_goals(path=goal_path)
  let mayor = demo_mayor()
  let saved = match snapshot {
    Some(saved) => saved
    None => {
      let state = load_or_create_demo_state(
        path=snapshot_path,
        book_catalog_path~,
      )
      @storage.snapshot_of(state)
    }
  }
  let state = saved.town
  let next_tick_sequence = daemon.tick_sequence + 1
  let updated_goals = dispatch_due_standing_goals(
    state, standing_goals, next_tick_sequence, snapshot_path, book_catalog_path,
  )
  @storage.save_standing_goals_file(goal_path, updated_goals)
  run_supervision_cycle(state, mayor, catalog)
  persist_town_checkpoint(state, snapshot_path)
  let report = @health.inspect_town(state)
  let (next_daemon, tick, _) = @scheduler.plan_daemon_tick(
    daemon,
    state,
    report,
    standing_goals~,
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

///|
async fn dispatch_due_standing_goals(
  state : @core.TownState,
  goals : Array[@core.StandingGoal],
  tick : Int,
  snapshot_path : String,
  book_catalog_path : String,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  for goal in goals {
    if goal.is_due(tick) {
      let target = goal.target_book_id.unwrap_or("mayor-selected-book")
      state.record_event(
        @core.TownEvent::new(
          id="event-standing-goal-\{tick}-\{goal.id}",
          kind="standing-goal",
          detail="Mayor dispatched standing goal \{goal.id} to \{target}: \{goal.title}",
          related_book_id=goal.target_book_id,
        ),
      )
      ignore(
        run_goal_into_state(
          state,
          goal.prompt,
          book_id=goal.target_book_id,
          task_limit_per_book=1,
          snapshot_path~,
          book_catalog_path~,
        ),
      )
      updated.push(goal.mark_dispatched(tick))
    } else {
      updated.push(goal)
    }
  }
  updated
}

///|
pub async fn daemon_run_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  max_ticks? : Int = 0,
  sleep_ms? : Int = 30_000,
) -> String {
  let mut ticks = 0
  let mut latest = ""
  while max_ticks <= 0 || ticks < max_ticks {
    latest = daemon_tick_saved_town(snapshot_path~, book_catalog_path~)
    ticks += 1
    if max_ticks > 0 && ticks >= max_ticks {
      break
    }
    @async.sleep(sleep_ms)
  }
  "Moontown daemon run completed ticks=\{ticks}\n\{latest}"
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
fn default_standing_goal_state_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    @storage.default_standing_goal_path()
  } else {
    "\{base}/standing-goals.json"
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
