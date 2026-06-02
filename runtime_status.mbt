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
  enabled_standing_goal_count : Int
  disabled_standing_goal_count : Int
  due_standing_goal_count : Int
  watcher_record_count : Int
  watcher_summary : String
  book_template_request_count : Int
  pending_book_template_request_count : Int
  failed_book_template_request_count : Int
  book_template_request_summary : String
  book_template_latest_event_summary : String
  daemon_tick : Int
  daemon_actions : Array[@scheduler.SchedulerAction]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

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
      let watcher_records = load_watcher_records_for_goals(snapshot_path, goals)
      let template_request_status = inspect_book_template_request_status(
        request_path=default_book_template_request_path(snapshot_path~),
      )
      let daemon_tick = effective_daemon_tick(
        snapshot_path,
        daemon,
        snapshot.town,
        goals,
        watcher_records,
      )
      runtime_status_from_state(
        snapshot.town,
        snapshot_path,
        standing_goals=goals,
        daemon_tick~,
        watcher_records~,
        book_template_request_status=Some(template_request_status),
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
        enabled_standing_goal_count: 0,
        disabled_standing_goal_count: 0,
        due_standing_goal_count: 0,
        watcher_record_count: 0,
        watcher_summary: "No watcher ledger records.",
        book_template_request_count: 0,
        pending_book_template_request_count: 0,
        failed_book_template_request_count: 0,
        book_template_request_summary: "No book-template request inbox.",
        book_template_latest_event_summary: "none",
        daemon_tick: 0,
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
  watcher_records? : Array[@core.WatcherRunRecord] = [],
  book_template_request_status? : BookTemplateRequestStatus? = None,
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
  let failed = count_runtime_anomalies(report, "execution-failed")
  let stale = count_runtime_executions(state, [@core.TaskExecutionStatus::Stale])
  let completed = count_runtime_executions(state, [
    @core.TaskExecutionStatus::Completed,
  ])
  let enabled_standing_goals = count_enabled_standing_goals(standing_goals)
  let disabled_standing_goals = count_disabled_standing_goals(standing_goals)
  let template_request_status = book_template_request_status.unwrap_or({
    request_path: default_book_template_request_path(snapshot_path~),
    event_path: default_book_template_request_event_path(
      request_path=default_book_template_request_path(snapshot_path~),
    ),
    request_count: 0,
    pending_count: 0,
    installed_count: 0,
    failed_count: 0,
    retry_count: 0,
    ready: true,
    summary: "book_template_requests=0 pending=0 retry=0 installed=0 failed=0",
    latest_event_summary: "none",
  })
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
    enabled_standing_goal_count: enabled_standing_goals,
    disabled_standing_goal_count: disabled_standing_goals,
    due_standing_goal_count: due_goals.length(),
    watcher_record_count: watcher_records.length(),
    watcher_summary: watcher_status_summary(watcher_records, standing_goals),
    book_template_request_count: template_request_status.request_count,
    pending_book_template_request_count: template_request_status.pending_count +
    template_request_status.retry_count,
    failed_book_template_request_count: template_request_status.failed_count,
    book_template_request_summary: template_request_status.summary,
    book_template_latest_event_summary: template_request_status.latest_event_summary,
    daemon_tick,
    daemon_actions: actions,
    summary: "books=\{state.books.length()} workers=\{state.workers.length()} tasks=\{state.tasks.length()} executions=\{state.executions.length()} running=\{running} review=\{review} failed=\{failed} stale=\{stale} standing_goals=\{standing_goals.length()} enabled_standing_goals=\{enabled_standing_goals} disabled_standing_goals=\{disabled_standing_goals} due_goals=\{due_goals.length()} watcher_records=\{watcher_records.length()} book_template_requests=\{template_request_status.request_count} pending_template_requests=\{template_request_status.pending_count + template_request_status.retry_count} failed_template_requests=\{template_request_status.failed_count} planned_actions=\{actions.length()}",
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
  max_int(
    max_int(
      max_int(
        daemon.tick_sequence,
        latest_daemon_log_sequence(default_daemon_log_path(snapshot_path~)),
      ),
      latest_live_autonomy_journal_tick(snapshot_path),
    ),
    max_int(
      max_int(
        latest_standing_goal_tick(standing_goals),
        latest_watcher_record_tick(watcher_records),
      ),
      latest_execution_task_tick(state),
    ),
  )
}

///|
fn count_runtime_anomalies(
  report : @health.HealthReport,
  title : String,
) -> Int {
  let mut count = 0
  for anomaly in report.anomalies {
    if anomaly.title == title {
      count += 1
    }
  }
  count
}

///|
fn count_runtime_executions(
  state : @core.TownState,
  statuses : Array[@core.TaskExecutionStatus],
) -> Int {
  let mut count = 0
  for index in 0..<state.executions.length() {
    let execution = state.executions[index]
    if !effective_execution_record(state, index) {
      continue
    }
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
fn effective_execution_record(state : @core.TownState, index : Int) -> Bool {
  let current = state.executions[index]
  for other_index in 0..<state.executions.length() {
    if other_index == index {
      continue
    }
    let other = state.executions[other_index]
    if other.task_id != current.task_id {
      continue
    }
    let other_rank = execution_status_rank(other.status)
    let current_rank = execution_status_rank(current.status)
    if other_rank > current_rank ||
      (other_rank == current_rank && other_index > index) {
      return false
    }
  }
  true
}

///|
fn execution_status_rank(status : @core.TaskExecutionStatus) -> Int {
  match status {
    PacketReady => 1
    ProposalImported => 2
    RunConfirmed | Running | AwaitingPersistence => 3
    ReviewQueued | Completed | Stale | Failed => 4
  }
}

///|
pub async fn render_saved_town_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let status = inspect_saved_town(snapshot_path~)
  let daemon = load_daemon_state(default_daemon_state_path(snapshot_path))
  let runtime = inspect_daemon_runtime(snapshot_path~)
  let builder = StringBuilder::new()
  builder.write_string("Moontown status\n")
  builder.write_string("\{status.summary}\n")
  if !status.has_snapshot {
    return builder.to_string()
  }
  builder.write_string("snapshot=\{status.snapshot_path}\n")
  builder.write_string(
    "daemon=\{daemon.daemon_id} tick=\{status.daemon_tick} saved_tick=\{daemon.tick_sequence} lease=\{daemon.lease_owner} jobs=\{daemon.jobs.length()}\n",
  )
  builder.write_string("\{daemon_runtime_health_summary(runtime)}\n")
  builder.write_string(
    "standing_goals=\{status.standing_goal_count} enabled=\{status.enabled_standing_goal_count} disabled=\{status.disabled_standing_goal_count} due_next_tick=\{status.due_standing_goal_count}\n",
  )
  builder.write_string(
    "watcher_records=\{status.watcher_record_count} \{status.watcher_summary}\n",
  )
  builder.write_string(
    "book_template_requests=\{status.book_template_request_count} pending=\{status.pending_book_template_request_count} failed=\{status.failed_book_template_request_count} \{status.book_template_request_summary}\n",
  )
  builder.write_string(
    "book_template_latest_event=\{status.book_template_latest_event_summary}\n",
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
  respect_runtime_lock? : Bool = true,
) -> String {
  if respect_runtime_lock && daemon_tick_runtime_lock_active(snapshot_path) {
    return "Moontown daemon tick skipped because another live daemon worker is already ticking. Use the existing daemon loop instead of overlapping manual ticks."
  }
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let daemon_path = default_daemon_state_path(snapshot_path)
  let log_path = default_daemon_log_path(snapshot_path~)
  let goal_path = default_standing_goal_state_path(snapshot_path)
  let standing_goals = @storage.load_or_create_standing_goals(path=goal_path)
  let watcher_records_for_floor = load_watcher_records_for_goals(
    snapshot_path, standing_goals,
  )
  let state = load_or_create_demo_state(path=snapshot_path, book_catalog_path~)
  let loaded_daemon = load_daemon_state(daemon_path)
  let mut tick_floor = loaded_daemon.tick_sequence
  for
    candidate in [
      latest_daemon_log_sequence(log_path),
      latest_live_autonomy_journal_tick(snapshot_path),
      latest_standing_goal_tick(standing_goals),
      latest_watcher_record_tick(watcher_records_for_floor),
      latest_execution_task_tick(state),
    ] {
    if candidate > tick_floor {
      tick_floor = candidate
    }
  }
  let daemon = if tick_floor > loaded_daemon.tick_sequence {
    @scheduler.DaemonState::new(
      daemon_id=loaded_daemon.daemon_id,
      lease_owner=loaded_daemon.lease_owner,
      tick_sequence=tick_floor,
      last_heartbeat_event_count=loaded_daemon.last_heartbeat_event_count,
      active_goal_ids=loaded_daemon.active_goal_ids,
      jobs=loaded_daemon.jobs,
    )
  } else {
    loaded_daemon
  }
  if daemon.tick_sequence > loaded_daemon.tick_sequence {
    save_daemon_state(daemon_path, daemon)
  }
  let mayor = demo_mayor()
  let next_tick_sequence = daemon.tick_sequence + 1
  append_daemon_log(log_path, "tick phase=start sequence=\{next_tick_sequence}")
  append_daemon_log(
    log_path,
    "tick phase=supervision sequence=\{next_tick_sequence}",
  )
  run_supervision_cycle(
    state,
    mayor,
    catalog,
    snapshot_path~,
    standing_goals~,
    tick=Some(next_tick_sequence),
  )
  append_daemon_log(
    log_path,
    "tick phase=standing-goals sequence=\{next_tick_sequence}",
  )
  let standing_goals_after_supervision_raw = @storage.load_or_create_standing_goals(
    path=goal_path,
  )
  let standing_goals_after_supervision = reconcile_budget_deferred_standing_goal_state(
    state, standing_goals_after_supervision_raw, snapshot_path,
  )
  @storage.save_standing_goals_file(goal_path, standing_goals_after_supervision)
  let updated_goals = dispatch_due_standing_goals(
    state, mayor, catalog, standing_goals_after_supervision, next_tick_sequence,
    snapshot_path,
  )
  let merged_updated_goals = merge_standing_goal_updates(
    @storage.load_or_create_standing_goals(path=goal_path),
    updated_goals,
  )
  @storage.save_standing_goals_file(goal_path, merged_updated_goals)
  reconcile_review_queued_standing_watch_outputs(
    state, catalog, snapshot_path, merged_updated_goals,
  )
  reconcile_persisted_non_review_outputs(state, snapshot_path)
  reconcile_transient_dependency_failures(state)
  append_daemon_log(
    log_path,
    "tick phase=scheduled-jobs sequence=\{next_tick_sequence}",
  )
  run_daemon_scheduled_jobs(
    state,
    daemon.jobs,
    snapshot_path,
    book_catalog_path,
    next_tick_sequence,
    log_path,
  )
  let standing_goals_for_projection = @storage.load_or_create_standing_goals(
    path=goal_path,
  )
  append_daemon_log(
    log_path,
    "tick phase=planbook sequence=\{next_tick_sequence}",
  )
  let planbook_summary = write_moontown_planbook_autonomy(
    snapshot_path~,
    book_catalog_path~,
  )
  let repair_active = planbook_repair_active_count(snapshot_path~)
  let planbook_repair_summary = if repair_active == 0 {
    write_moontown_planbook_repair_task(
      snapshot_path~,
      book_catalog_path~,
      dispatch=true,
      run_inline=false,
    )
  } else {
    "PlanBook repair already active; daemon did not create a duplicate repair task."
  }
  let watcher_records = load_watcher_records_for_goals(
    snapshot_path, standing_goals_for_projection,
  )
  append_daemon_log(
    log_path,
    "tick phase=projection sequence=\{next_tick_sequence}",
  )
  persist_visual_projection(state, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  let report = @health.inspect_town(state)
  let (next_daemon, tick, _) = @scheduler.plan_daemon_tick(
    daemon,
    state,
    report,
    standing_goals=standing_goals_for_projection,
  )
  save_daemon_state(daemon_path, next_daemon)
  append_daemon_log(log_path, "tick phase=done sequence=\{next_tick_sequence}")
  state.record_event(
    @core.TownEvent::new(
      id="event-daemon-\{tick.sequence}",
      kind="daemon",
      detail=tick.summary,
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-planbook-\{tick.sequence}",
      kind="planbook",
      detail=planbook_summary,
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-planbook-repair-\{tick.sequence}",
      kind="planbook-repair",
      detail=planbook_repair_summary,
    ),
  )
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      standing_goals=standing_goals_for_projection,
      watcher_records~,
      tick_summary=tick.summary,
      daemon_tick=Some(tick.sequence),
    ),
  )
  persist_visual_projection(state, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  render_saved_town_status(snapshot_path~)
}

///|
async fn daemon_tick_runtime_lock_active(snapshot_path : String) -> Bool {
  let runtime = inspect_daemon_runtime(snapshot_path~)
  runtime.status == "ticking" &&
  runtime.worker_alive &&
  !runtime.stale &&
  runtime.heartbeat_age_ms < 120_000UL
}

///|
async fn dispatch_due_standing_goals(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goals : Array[@core.StandingGoal],
  tick : Int,
  snapshot_path : String,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  let mut dispatches = 0
  for offset in 0..<goals.length() {
    let goal = goals[standing_goal_dispatch_index(offset, goals.length(), tick)]
    if goal.is_due(tick) {
      if dispatches >= max_standing_goal_dispatches_per_tick() {
        state.record_event(
          @core.TownEvent::new(
            id="event-standing-goal-\{tick}-\{goal.id}-deferred-budget",
            kind="standing-goal",
            detail="Mayor deferred standing goal \{goal.id} because this daemon tick already used its bounded standing-goal dispatch budget.",
            related_book_id=goal.target_book_id,
          ),
        )
        updated.push(goal)
        continue
      }
      if live_external_execution_count(state) >= max_live_external_executions() {
        state.record_event(
          @core.TownEvent::new(
            id="event-standing-goal-\{tick}-\{goal.id}-deferred-cap",
            kind="standing-goal",
            detail="Mayor deferred standing goal \{goal.id} because live external execution count reached \{max_live_external_executions()}.",
            related_book_id=goal.target_book_id,
          ),
        )
        updated.push(goal)
        continue
      }
      let target = goal.target_book_id.unwrap_or("mayor-selected-book")
      state.record_event(
        @core.TownEvent::new(
          id="event-standing-goal-\{tick}-\{goal.id}",
          kind="standing-goal",
          detail="Mayor dispatched standing goal \{goal.id} to \{target}: \{goal.title}",
          related_book_id=goal.target_book_id,
        ),
      )
      dispatches += 1
      updated.push(
        run_standing_goal_watch_cycle(
          state, mayor, catalog, goal, tick, snapshot_path,
        ),
      )
    } else {
      updated.push(goal)
    }
  }
  updated
}

///|
fn standing_goal_dispatch_index(
  offset : Int,
  goal_count : Int,
  tick : Int,
) -> Int {
  if goal_count <= 0 {
    0
  } else {
    (tick + offset) % goal_count
  }
}

///|
fn max_standing_goal_dispatches_per_tick() -> Int {
  1
}

///|
fn merge_standing_goal_updates(
  latest : Array[@core.StandingGoal],
  updated : Array[@core.StandingGoal],
) -> Array[@core.StandingGoal] {
  let merged : Array[@core.StandingGoal] = []
  for goal in latest {
    match find_runtime_standing_goal_by_id(updated, goal.id) {
      Some(next) => merged.push(next)
      None => merged.push(goal)
    }
  }
  for goal in updated {
    if find_runtime_standing_goal_by_id(merged, goal.id) is None {
      merged.push(goal)
    }
  }
  merged
}

///|
async fn reconcile_budget_deferred_standing_goal_state(
  state : @core.TownState,
  goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> Array[@core.StandingGoal] {
  let watcher_records = load_watcher_records_for_goals(snapshot_path, goals)
  goals.map(fn(goal) {
    match goal.last_run_tick {
      Some(last_run_tick) =>
        if standing_goal_has_nonexecuted_deferred_event(
            state,
            goal.id,
            last_run_tick,
          ) &&
          !standing_goal_has_watcher_record_at_tick(
            watcher_records,
            goal.id,
            last_run_tick,
          ) {
          state.record_event(
            @core.TownEvent::new(
              id="event-standing-goal-\{last_run_tick}-\{goal.id}-budget-state-repaired",
              kind="standing-goal",
              detail="Mayor restored standing goal \{goal.id} to due state because tick \{last_run_tick} was only scheduler-deferred and produced no watcher ledger record.",
              related_book_id=goal.target_book_id,
            ),
          )
          @core.StandingGoal::new(
            id=goal.id,
            title=goal.title,
            prompt=goal.prompt,
            target_book_id=goal.target_book_id,
            cadence_ticks=goal.cadence_ticks,
            next_due_tick=last_run_tick,
            last_run_tick=latest_watcher_record_tick_for_goal_before(
              watcher_records,
              goal.id,
              last_run_tick,
            ),
            enabled=goal.enabled,
            source_policy=goal.source_policy,
            quality_threshold=goal.quality_threshold,
          )
        } else {
          goal
        }
      None => goal
    }
  })
}

///|
fn standing_goal_has_nonexecuted_deferred_event(
  state : @core.TownState,
  goal_id : String,
  tick : Int,
) -> Bool {
  let budget_event_id = "event-standing-goal-\{tick}-\{goal_id}-deferred-budget"
  let cap_event_id = "event-standing-goal-\{tick}-\{goal_id}-deferred-cap"
  state.events.any(fn(event) {
    event.id == budget_event_id || event.id == cap_event_id
  })
}

///|
fn standing_goal_has_watcher_record_at_tick(
  records : Array[@core.WatcherRunRecord],
  goal_id : String,
  tick : Int,
) -> Bool {
  records.any(fn(record) { record.goal_id == goal_id && record.tick == tick })
}

///|
fn latest_watcher_record_tick_for_goal_before(
  records : Array[@core.WatcherRunRecord],
  goal_id : String,
  tick : Int,
) -> Int? {
  let mut latest = 0
  for record in records {
    if record.goal_id == goal_id && record.tick < tick && record.tick > latest {
      latest = record.tick
    }
  }
  if latest > 0 {
    Some(latest)
  } else {
    None
  }
}

///|
fn find_runtime_standing_goal_by_id(
  goals : Array[@core.StandingGoal],
  id : String,
) -> @core.StandingGoal? {
  for goal in goals {
    if goal.id == id {
      return Some(goal)
    }
  }
  None
}

///|
async fn load_watcher_records_for_goals(
  snapshot_path : String,
  goals : Array[@core.StandingGoal],
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  for goal in goals {
    for record in @storage.load_watcher_run_records(goal.id, dir=ledger_dir) {
      records.push(record)
    }
  }
  records
}

///|
fn watcher_status_summary(
  records : Array[@core.WatcherRunRecord],
  goals : Array[@core.StandingGoal],
) -> String {
  if records.is_empty() {
    return "latest=none"
  }
  let mut latest = records[0]
  for record in records {
    if watcher_record_prefer_candidate(latest, record) {
      latest = record
    }
  }
  let current_next = current_goal_next_due_tick(latest.goal_id, goals)
  let latest_decision = watcher_record_effective_decision(latest).to_string()
  match current_next {
    Some(next_due_tick) =>
      if next_due_tick == latest.next_due_tick {
        "latest=\{latest.goal_id}/\{latest_decision} next_due_tick=\{latest.next_due_tick}"
      } else {
        "latest=\{latest.goal_id}/\{latest_decision} recorded_next_due_tick=\{latest.next_due_tick} current_next_due_tick=\{next_due_tick}"
      }
    None =>
      "latest=\{latest.goal_id}/\{latest_decision} next_due_tick=\{latest.next_due_tick}"
  }
}

///|
fn latest_watcher_record_tick(records : Array[@core.WatcherRunRecord]) -> Int {
  let mut tick = 0
  for record in records {
    if record.tick > tick {
      tick = record.tick
    }
  }
  tick
}

///|
fn latest_standing_goal_tick(goals : Array[@core.StandingGoal]) -> Int {
  let mut tick = 0
  for goal in goals {
    match goal.last_run_tick {
      Some(last_run_tick) => if last_run_tick > tick { tick = last_run_tick }
      None => ()
    }
  }
  tick
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

///|
async fn latest_daemon_log_sequence(log_path : String) -> Int {
  let text = read_text_or_empty(log_path)
  let mut latest = 0
  for line in text.split("\n") {
    if !line.contains("sequence=") {
      continue
    }
    let parts = line.split("sequence=").to_array()
    match parts.get(parts.length() - 1) {
      Some(suffix) =>
        match first_non_negative_int(suffix.to_owned()) {
          Some(value) => if value > latest { latest = value }
          None => ()
        }
      None => ()
    }
  }
  latest
}

///|
fn current_goal_next_due_tick(
  goal_id : String,
  goals : Array[@core.StandingGoal],
) -> Int? {
  for goal in goals {
    if goal.id == goal_id {
      return Some(goal.next_due_tick)
    }
  }
  None
}

///|
pub async fn daemon_run_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  max_ticks? : Int = 0,
  sleep_ms? : Int = 30_000,
  preserve_supervisor? : Bool = false,
  inline_under_supervisor? : Bool = false,
) -> String {
  let log_path = default_daemon_log_path(snapshot_path~)
  let observed_worker_pid = daemon_current_process_pid(snapshot_path)
  let prior_health = inspect_daemon_runtime(snapshot_path~)
  let prior_state = load_daemon_runtime_state(
    default_daemon_runtime_path(snapshot_path~),
  )
  let worker_pid = if inline_under_supervisor &&
    prior_health.supervisor_pid > 0 &&
    prior_health.supervisor_alive {
    prior_health.supervisor_pid
  } else if prior_health.worker_pid > 0 &&
    prior_health.worker_alive &&
    !prior_health.stale {
    prior_health.worker_pid
  } else {
    observed_worker_pid
  }
  let worker_run_id = match prior_state {
    Some(state) if worker_pid == state.worker_pid &&
      !state.worker_run_id.is_empty() => state.worker_run_id
    _ => daemon_run_id("worker")
  }
  if inline_under_supervisor &&
    worker_pid > 0 &&
    prior_health.supervisor_pid == 0 {
    let supervisor_run_id = match prior_state {
      Some(state) if !state.supervisor_run_id.is_empty() =>
        state.supervisor_run_id
      _ => daemon_run_id("supervisor")
    }
    mark_daemon_supervisor_started(snapshot_path, worker_pid, supervisor_run_id)
  }
  if worker_pid > 0 {
    mark_daemon_worker_started(
      snapshot_path,
      worker_pid,
      worker_run_id,
      clear_supervisor=!preserve_supervisor,
    )
  }
  append_daemon_log(
    log_path,
    "worker loop entered run=\{worker_run_id} pid=\{worker_pid} max_ticks=\{max_ticks} sleep_ms=\{sleep_ms}",
  )
  let mut ticks = 0
  let mut latest = ""
  while max_ticks <= 0 || ticks < max_ticks {
    if daemon_stop_requested(snapshot_path) {
      latest = "daemon stop requested"
      break
    }
    if daemon_restart_requested(snapshot_path) {
      latest = "daemon restart requested"
      break
    }
    mark_daemon_tick_started(snapshot_path, worker_run_id)
    let (ok, tick_summary) = run_daemon_tick_with_heartbeat(
      snapshot_path, book_catalog_path,
    )
    latest = tick_summary
    mark_daemon_tick_finished(snapshot_path, ok, latest)
    append_daemon_log(
      log_path,
      if ok {
        "tick ok index=\{ticks + 1}"
      } else {
        "tick failed index=\{ticks + 1}: \{latest}"
      },
    )
    ticks += 1
    if max_ticks > 0 && ticks >= max_ticks {
      break
    }
    @async.sleep(sleep_ms)
  }
  if latest == "daemon stop requested" {
    mark_daemon_stopped(snapshot_path, "worker stopped by request")
    append_daemon_log(log_path, "worker stopped run=\{worker_run_id}")
  } else if latest == "daemon restart requested" {
    mark_daemon_worker_reload_requested(
      snapshot_path, "worker reload requested by restart marker",
    )
    append_daemon_log(log_path, "worker reload requested run=\{worker_run_id}")
  } else if max_ticks > 0 {
    mark_daemon_stopped(snapshot_path, "worker completed bounded run")
    append_daemon_log(log_path, "worker completed bounded run=\{worker_run_id}")
  }
  "Moontown daemon run completed ticks=\{ticks}\n\{latest}"
}

///|
async fn run_daemon_tick_with_heartbeat(
  snapshot_path : String,
  book_catalog_path : String,
) -> (Bool, String) {
  @async.with_task_group(group => {
    let mut done = false
    let heartbeat = group.spawn(() => {
      while !done {
        @async.sleep(10_000)
        if !done {
          touch_daemon_heartbeat(snapshot_path, status="ticking")
        }
      }
    })
    let mut ok = true
    let summary = daemon_tick_saved_town(
      snapshot_path~,
      book_catalog_path~,
      respect_runtime_lock=false,
    ) catch {
      error => {
        ok = false
        "daemon tick failed: \{error}"
      }
    }
    done = true
    heartbeat.wait()
    (ok, summary)
  })
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
