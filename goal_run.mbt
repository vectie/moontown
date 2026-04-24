///|
pub async fn run_goal(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  let plan = mayor.plan_goal(catalog, goal, explicit_book_id=book_id)
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  let books : Array[@core.BookRef] = []
  for lane in plan.lanes {
    books.push(lane.entry.to_book_ref())
  }
  register_demo_books(state, books)
  register_demo_workers(state)
  state.record_event(
    @core.TownEvent::new(
      id="event-goal",
      kind="goal",
      detail="Accepted town goal: \{goal}",
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-goal-plan",
      kind="planning",
      detail=plan.summary,
    ),
  )
  persist_town_checkpoint(state, snapshot_path)
  let limit = if task_limit_per_book < 1 { 1 } else { task_limit_per_book }
  let launches : Array[GoalBookLaunch] = []
  for lane in plan.lanes {
    match prepare_goal_book_launch(state, lane.entry, lane.objective, limit) {
      Some(launch) => launches.push(launch)
      None => ()
    }
  }
  for launch in launches {
    launch_goal_book(state, mayor, launch)
    persist_town_checkpoint(state, snapshot_path)
  }
  wait_for_goal_settle(state, mayor, catalog, snapshot_path)
  write_town_goal_synthesis(state, goal, plan, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  state
}

///|
pub async fn render_goal_run(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let state = run_goal(
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
  render_state_dashboard(state)
}

///|
pub async fn supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let snapshot = @storage.load_snapshot_file(snapshot_path)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  match snapshot {
    Some(saved) => {
      let state = saved.town
      run_supervision_cycle(state, mayor, catalog)
      persist_town_checkpoint(state, snapshot_path)
      render_state_dashboard(state)
    }
    None => "No saved town snapshot exists at \{snapshot_path}."
  }
}

///|
async fn persist_town_checkpoint(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
}

///|
priv struct GoalBookLaunch {
  entry : @moonbook.BookCatalogEntry
  tasks : Array[@moonbook.BookTask]
}

///|
async fn prepare_goal_book_launch(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> GoalBookLaunch? {
  let acceptance = @moonbook.accept_goal(entry, objective) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-accept-\{entry.id}",
          kind="error",
          detail="MoonBook accept failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-accept-\{entry.id}",
      kind="accept",
      detail="MoonBook accepted \{entry.id}: \{acceptance.summary}",
      related_book_id=Some(entry.id),
    ),
  )
  let initial_summary = @moonbook.summarize_state(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-preflight-\{entry.id}",
          kind="error",
          detail="MoonBook preflight summary failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  let batch = @moonbook.produce_task_batch(entry, objective) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-plan-\{entry.id}",
          kind="error",
          detail="MoonBook planning failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  let bootstrap = research_bootstrap_plan(
    entry,
    objective,
    initial_summary,
    batch.tasks,
    task_limit,
  )
  if bootstrap.bootstrap_active {
    state.record_event(
      @core.TownEvent::new(
        id="event-bootstrap-\{entry.id}",
        kind="planning",
        detail="Bootstrap ingest-first plan for \{entry.id}: evidence=\{initial_summary.evidence_count} verified_sources=\{initial_summary.verified_source_count} candidate_sources=\{initial_summary.candidate_source_count} tasks=\{bootstrap.tasks.length()} limit=\{bootstrap.task_limit}",
        related_book_id=Some(entry.id),
      ),
    )
  }
  let selected_tasks : Array[@moonbook.BookTask] = []
  let mut emitted = 0
  for task in bootstrap.tasks {
    if emitted >= bootstrap.task_limit {
      break
    }
    selected_tasks.push(task)
    emitted += 1
  }
  Some({ entry, tasks: selected_tasks })
}

///|
async fn launch_goal_book(
  state : @core.TownState,
  mayor : @roles.Mayor,
  launch : GoalBookLaunch,
) -> Unit {
  for task in launch.tasks {
    let planned_task = to_town_task(
      launch.entry,
      task,
      @core.TaskExecutionStatus::PacketReady,
    )
    let decision = mayor.decide_dispatch(state, planned_task)
    state.record_event(route_event(decision.decision, state.events.length()))
    let worker_id = assigned_worker_id(decision.decision)
    let execution = execute_goal_book_task(
      mayor,
      launch.entry,
      task,
      assigned_worker_id=worker_id,
      tick=supervision_tick(state),
    ) catch {
      error =>
        failed_execution_record(
          launch.entry,
          task,
          "Goal execution failed for \{launch.entry.id} / \{task.id}: \{error}",
        )
    }
    state.replace_task(to_town_task(launch.entry, task, execution.status))
    state.replace_execution(execution)
    sync_worker_from_execution(state, execution)
    state.record_event(
      execution_event(execution, state.executions.length() - 1),
    )
    persist_execution_into_book(state, launch.entry, execution)
  }
}

///|
async fn finalize_goal_book_entry(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  pending_review_baseline : Int,
  task_ids : Array[String],
) -> Unit {
  let generated_index = @moonbook.build_workspace(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-build-\{entry.id}",
          kind="error",
          detail="MoonBook build failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return
    }
  }
  let summary = @moonbook.summarize_state(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-summary-\{entry.id}",
          kind="error",
          detail="MoonBook summary failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return
    }
  }
  if summary.pending_review_count > pending_review_baseline {
    queue_book_review_backlog(
      state,
      entry.id,
      task_ids,
      summary.pending_review_count,
    )
  }
  let quality_gaps = research_quality_gaps(entry)
  let readiness = ResearchReadiness::from_summary(
    summary,
    extra_gaps=quality_gaps,
  )
  if !quality_gaps.is_empty() {
    queue_research_quality_gate(state, entry.id, task_ids, quality_gaps)
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-build-\{entry.id}",
      kind="projection",
      detail="Generated site for \{entry.id}: \{generated_index}",
      related_book_id=Some(entry.id),
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-summary-\{entry.id}",
      kind="summary",
      detail="Book summary \{entry.id}: pages=\{summary.page_count} evidence=\{summary.evidence_count} pending_review=\{summary.pending_review_count} quality_gaps=\{quality_gaps.length()} readiness=\{readiness.summary_line()}",
      related_book_id=Some(entry.id),
    ),
  )
}
