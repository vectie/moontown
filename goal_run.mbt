///|
pub async fn run_goal(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  run_goal_into_state(
    state,
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
}

///|
async fn run_goal_into_state(
  state : @core.TownState,
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  let plan = mayor.plan_goal(catalog, goal, explicit_book_id=book_id)
  let books : Array[@core.BookRef] = []
  for lane in plan.lanes {
    books.push(lane.entry.to_book_ref())
  }
  register_demo_books(state, books)
  register_demo_workers(state)
  let event_index = state.events.length()
  state.record_event(
    @core.TownEvent::new(
      id="event-goal-\{event_index}",
      kind="goal",
      detail="Accepted town goal: \{goal}",
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-goal-plan-\{event_index}",
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
  persist_visual_projection(state, snapshot_path)
}

///|
priv struct GoalBookLaunch {
  entry : @moonbook.BookCatalogEntry
  tasks : Array[@moonbook.BookTask]
  pending_review_baseline : Int
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
  preseed_goal_bootstrap_inputs(entry, objective) catch {
    error =>
      state.record_event(
        @core.TownEvent::new(
          id="event-preseed-\{entry.id}",
          kind="error",
          detail="Moontown failed to preseed bootstrap inputs for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
  }
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
  let plan = match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) => {
      state.record_event(
        @core.TownEvent::new(
          id="event-civic-plan-\{entry.id}",
          kind="planning",
          detail="Wenyu civic service plan for \{entry.id}: dispatching \{service.title} service workflow before any product-build or research-bootstrap tasks.",
          related_book_id=Some(entry.id),
        ),
      )
      wenyu_civic_service_plan(entry, objective, batch.tasks, task_limit)
    }
    None => {
      let bootstrap = research_bootstrap_plan(
        entry,
        objective,
        initial_summary,
        batch.tasks,
        task_limit,
      )
      if is_wenyu_book(entry) && wenyu_book_ready_for_build(entry) {
        state.record_event(
          @core.TownEvent::new(
            id="event-build-plan-\{entry.id}",
            kind="planning",
            detail="Wenyu build-stage plan for \{entry.id}: research quality passed; dispatching implementation, code, and asset tasks.",
            related_book_id=Some(entry.id),
          ),
        )
        wenyu_build_plan(entry, objective, task_limit)
      } else {
        bootstrap
      }
    }
  }
  if plan.bootstrap_active {
    state.record_event(
      @core.TownEvent::new(
        id="event-bootstrap-\{entry.id}",
        kind="planning",
        detail="Bootstrap ingest-first plan for \{entry.id}: evidence=\{initial_summary.evidence_count} verified_sources=\{initial_summary.verified_source_count} candidate_sources=\{initial_summary.candidate_source_count} tasks=\{plan.tasks.length()} limit=\{plan.task_limit}",
        related_book_id=Some(entry.id),
      ),
    )
  }
  let selected_tasks : Array[@moonbook.BookTask] = []
  let mut emitted = 0
  for task in plan.tasks {
    if emitted >= plan.task_limit {
      break
    }
    selected_tasks.push(task)
    emitted += 1
  }
  Some({
    entry,
    tasks: selected_tasks,
    pending_review_baseline: initial_summary.pending_review_count,
  })
}

///|
async fn launch_goal_book(
  state : @core.TownState,
  mayor : @roles.Mayor,
  launch : GoalBookLaunch,
) -> Unit {
  for task in launch.tasks {
    let tick = supervision_tick(state)
    let planned_task = to_town_task(
      launch.entry,
      task,
      @core.TaskExecutionStatus::PacketReady,
    )
    if live_external_execution_count(state) >= max_live_external_executions() {
      let queued_execution = queued_goal_execution_record(
        launch.entry,
        task,
        tick,
        "Mayor queued \{task.id} because live external execution count reached \{max_live_external_executions()}; the supervision loop will launch it when capacity is available.",
      )
      state.replace_task(planned_task)
      state.replace_execution(queued_execution)
      state.record_event(
        @core.TownEvent::new(
          id="event-queue-\{state.events.length()}-\{task.id}",
          kind="execution-queue",
          detail=queued_execution.summary,
          related_task_id=Some(task.id),
          related_book_id=Some(launch.entry.id),
        ),
      )
      continue
    }
    let decision = mayor.decide_dispatch(state, planned_task)
    state.record_event(route_event(decision.decision, state.events.length()))
    let worker_id = assigned_worker_id(decision.decision)
    let execution = execute_goal_book_task(
      mayor,
      launch.entry,
      task,
      assigned_worker_id=worker_id,
      tick~,
    ) catch {
      error =>
        failed_execution_record(
          launch.entry,
          task,
          "Goal execution failed for \{launch.entry.id} / \{task.id}: \{error}",
          assigned_worker_id=worker_id,
        )
    }
    let completed_execution = complete_wenyu_build_artifacts_if_needed(
      launch.entry,
      task,
      execution,
    )
    state.replace_task(
      to_town_task(launch.entry, task, completed_execution.status),
    )
    state.replace_execution(completed_execution)
    sync_worker_from_execution(state, completed_execution)
    state.record_event(
      execution_event(completed_execution, state.executions.length() - 1),
    )
    let reconciled_execution = match
      persist_execution_into_book(state, launch.entry, completed_execution) {
      Some(outcome) =>
        execution_after_successful_book_persist(
          completed_execution, outcome, tick,
        )
      None => completed_execution
    }
    if reconciled_execution != completed_execution {
      state.replace_task(
        to_town_task(launch.entry, task, reconciled_execution.status),
      )
      state.replace_execution(reconciled_execution)
      sync_worker_from_execution(state, reconciled_execution)
    }
    if terminal_execution_status(completed_execution.status) {
      finalize_goal_book_entry(
        state,
        launch.entry,
        launch.pending_review_baseline,
        [reconciled_execution.task_id],
      )
    }
  }
}

///|
fn queued_goal_execution_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  tick : Int,
  summary : String,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id="queued-\{entry.id}-\{task.id}",
    packet_path="",
    proposal_id=None,
    run_id=None,
    status=@core.TaskExecutionStatus::PacketReady,
    summary~,
    output_contract="moontown.queued.execution.v1",
    context_pages=task.target_pages,
    skill_paths=entry.skills,
    last_command=None,
    attempt=0,
    heartbeat_tick=tick,
    stale_after_tick=tick + 30,
    next_retry_tick=Some(tick + 1),
    requires_review=task.requires_review,
    notify_town=true,
  )
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
  } else {
    write_research_quality_review_resolved(entry, "post-run quality gate")
    complete_recovered_research_bootstrap_if_clean(state, entry.id, task_ids)
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
      detail="Book summary \{entry.id}: pages=\{summary.page_count} domain_evidence=\{summary.evidence_count} operational_evidence=\{summary.operational_evidence_count} total_evidence=\{summary.total_evidence_count} pending_review=\{summary.pending_review_count} quality_gaps=\{quality_gaps.length()} readiness=\{readiness.summary_line()}",
      related_book_id=Some(entry.id),
    ),
  )
}
