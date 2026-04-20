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
  for lane in plan.lanes {
    run_goal_for_book(state, mayor, lane.entry, lane.objective, limit)
    run_supervision_cycle(state, mayor, catalog)
    persist_town_checkpoint(state, snapshot_path)
  }
  run_supervision_cycle(state, mayor, catalog)
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
async fn run_goal_for_book(
  state : @core.TownState,
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> Unit {
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
      return
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
      return
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
      return
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
        detail="Bootstrap ingest-first plan for \{entry.id}: evidence=\{initial_summary.evidence_count} sources=\{initial_summary.source_count} tasks=\{bootstrap.tasks.length()} limit=\{bootstrap.task_limit}",
        related_book_id=Some(entry.id),
      ),
    )
  }
  let mut emitted = 0
  let emitted_task_ids : Array[String] = []
  for task in bootstrap.tasks {
    if emitted >= bootstrap.task_limit {
      break
    }
    let planned_task = to_town_task(
      entry,
      task,
      @core.TaskExecutionStatus::PacketReady,
    )
    let decision = mayor.decide_dispatch(state, planned_task)
    state.record_event(route_event(decision.decision, state.events.length()))
    let worker_id = assigned_worker_id(decision.decision)
    let execution = execute_goal_book_task(
      mayor,
      entry,
      task,
      assigned_worker_id=worker_id,
      tick=supervision_tick(state),
    ) catch {
      error =>
        failed_execution_record(
          entry,
          task,
          "Goal execution failed for \{entry.id} / \{task.id}: \{error}",
        )
    }
    state.replace_task(to_town_task(entry, task, execution.status))
    state.replace_execution(execution)
    sync_worker_from_execution(state, execution)
    state.record_event(
      execution_event(execution, state.executions.length() - 1),
    )
    persist_execution_into_book(state, entry, execution)
    emitted_task_ids.push(task.id)
    emitted += 1
  }
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
  if summary.pending_review_count > initial_summary.pending_review_count {
    queue_book_review_backlog(
      state,
      entry.id,
      emitted_task_ids,
      summary.pending_review_count,
    )
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
      detail="Book summary \{entry.id}: pages=\{summary.page_count} evidence=\{summary.evidence_count} pending_review=\{summary.pending_review_count}",
      related_book_id=Some(entry.id),
    ),
  )
}

///|
fn queue_book_review_backlog(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  pending_review_count : Int,
) -> Unit {
  let mut marked = 0
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / pending_review=\{pending_review_count}",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  if marked > 0 {
    state.record_event(
      @core.TownEvent::new(
        id="event-review-backlog-\{book_id}",
        kind="review",
        detail="Book \{book_id} still has \{pending_review_count} pending review items after execution; mayor marked \{marked} task(s) as review-queued.",
        related_book_id=Some(book_id),
      ),
    )
  }
}

///|
async fn persist_execution_into_book(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  if execution.summary.trim().is_blank() ||
    execution.status is @core.TaskExecutionStatus::RunConfirmed {
    return
  }
  let result = @moonbook.BookResult::new(
    task_id=execution.task_id,
    summary=execution.summary,
    artifacts=execution.run_id.map(fn(run_id) { [run_id] }).unwrap_or([]),
    requires_review=execution.requires_review ||
      execution.status is @core.TaskExecutionStatus::Running,
    notify_town=execution.notify_town,
  )
  let outcome = @moonbook.persist_result(entry, result) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-persist-\{entry.id}-\{execution.task_id}",
          kind="error",
          detail="MoonBook persist failed for \{entry.id} / \{execution.task_id}: \{error}",
          related_book_id=Some(entry.id),
          related_task_id=Some(execution.task_id),
          related_proposal_id=execution.proposal_id,
          related_run_id=execution.run_id,
        ),
      )
      return
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-persist-\{entry.id}-\{execution.task_id}",
      kind="persist",
      detail="MoonBook persisted \{execution.task_id}: pages=\{outcome.updated_pages.length()} review=\{outcome.review_queued} evidence=\{outcome.evidence_id}",
      related_book_id=Some(entry.id),
      related_task_id=Some(execution.task_id),
      related_proposal_id=execution.proposal_id,
      related_run_id=execution.run_id,
    ),
  )
}

///|
async fn execute_goal_book_task(
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
) -> @core.TaskExecutionRecord {
  let prepared = mayor.prepare_keeper_packet(entry, task)
  let workspace_root = @moonbook.workspace_root(entry)
  let imported = @moonclaw.import_packet(
    prepared.packet,
    prepared.packet_path,
    cwd=workspace_root,
    confirm=true,
  )
  let execution = match imported.run_id {
    Some(run_id) => ensure_run_execution(task.id, run_id, workspace_root)
    None => None
  }
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id=prepared.packet.packet_id,
    packet_path=prepared.packet_path,
    proposal_id=Some(imported.proposal_id),
    run_id=imported.run_id,
    status=execution
      .map(fn(result) { result.0.status })
      .unwrap_or(imported.status),
    summary=execution
      .map(fn(result) { result.0.summary })
      .unwrap_or(imported.summary),
    output_contract=prepared.packet.output_contract,
    context_pages=prepared.packet.context_pages,
    skill_paths=prepared.packet.skill_paths,
    last_command=Some(render_execution_commands(imported.command, execution)),
    assigned_worker_id~,
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + 3,
    next_retry_tick=None,
    requires_review=execution
      .map(fn(result) { result.0.requires_review })
      .unwrap_or(task.requires_review),
    notify_town=execution
      .map(fn(result) { result.0.notify_town })
      .unwrap_or(true),
  )
}

///|
async fn ensure_run_execution(
  task_id : String,
  run_id : String,
  workspace_root : String,
) -> (@moonclaw.ProposalPollResponse, String?)? {
  let initial = @moonclaw.poll_run(task_id, run_id, cwd=workspace_root)
  let launch_command = if initial.status
    is @core.TaskExecutionStatus::RunConfirmed {
    Some(@moonclaw.run_confirmed_run(run_id, cwd=workspace_root))
  } else {
    None
  }
  let current = @moonclaw.poll_run(task_id, run_id, cwd=workspace_root)
  Some((current, launch_command))
}

///|
fn render_execution_commands(
  import_command : String,
  execution : (@moonclaw.ProposalPollResponse, String?)?,
) -> String {
  match execution {
    Some((_, Some(run_command))) => "\{import_command}\n\{run_command}"
    _ => import_command
  }
}

///|
fn terminal_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::Completed => true
    @core.TaskExecutionStatus::Stale => true
    @core.TaskExecutionStatus::Failed => true
    _ => false
  }
}

///|
fn supervision_tick(state : @core.TownState) -> Int {
  state.events.length() + state.executions.length() + 1
}

///|
fn assigned_worker_id(decision : @dispatch.RouteDecision) -> String? {
  match decision {
    Assigned(plan) => Some(plan.worker_id)
    _ => None
  }
}

///|
fn sync_worker_from_execution(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  match execution.assigned_worker_id {
    Some(worker_id) =>
      state.set_worker_status(
        worker_id,
        worker_status_for_execution(execution.status),
      )
    None => ()
  }
}

///|
fn worker_status_for_execution(
  status : @core.TaskExecutionStatus,
) -> @core.WorkerStatus {
  match status {
    @core.TaskExecutionStatus::PacketReady => @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::ProposalImported => @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::RunConfirmed => @core.WorkerStatus::Running
    @core.TaskExecutionStatus::Running => @core.WorkerStatus::Running
    @core.TaskExecutionStatus::AwaitingPersistence =>
      @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::ReviewQueued => @core.WorkerStatus::Blocked
    @core.TaskExecutionStatus::Completed => @core.WorkerStatus::Idle
    @core.TaskExecutionStatus::Stale => @core.WorkerStatus::Blocked
    @core.TaskExecutionStatus::Failed => @core.WorkerStatus::Blocked
  }
}

///|
fn copy_execution_with(
  execution : @core.TaskExecutionRecord,
  status? : @core.TaskExecutionStatus = execution.status,
  summary? : String = execution.summary,
  attempt? : Int = execution.attempt,
  heartbeat_tick? : Int = execution.heartbeat_tick,
  stale_after_tick? : Int = execution.stale_after_tick,
  next_retry_tick? : Int? = execution.next_retry_tick,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id=execution.task_id,
    book_id=execution.book_id,
    packet_id=execution.packet_id,
    packet_path=execution.packet_path,
    proposal_id=execution.proposal_id,
    run_id=execution.run_id,
    status~,
    summary~,
    output_contract=execution.output_contract,
    context_pages=execution.context_pages,
    skill_paths=execution.skill_paths,
    last_command=execution.last_command,
    assigned_worker_id=execution.assigned_worker_id,
    attempt~,
    heartbeat_tick~,
    stale_after_tick~,
    next_retry_tick~,
    requires_review=execution.requires_review,
    notify_town=execution.notify_town,
  )
}

///|
fn copy_task_with_status(
  task : @core.TownTask,
  status : @core.TownTaskStatus,
) -> @core.TownTask {
  @core.TownTask::new(
    id=task.id,
    book_id=task.book_id,
    title=task.title,
    prompt=task.prompt,
    domain=task.domain,
    required_role=task.required_role,
    required_capabilities=task.required_capabilities,
    status~,
  )
}

///|
async fn run_supervision_cycle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  reconcile_live_executions(state, catalog)
  let packet = mayor.supervise(state, supervision_tick(state))
  if packet.directives.is_empty() {
    return
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-supervise-\{packet.tick}",
      kind="supervision",
      detail=packet.summary,
    ),
  )
  for directive in packet.directives {
    state.record_event(
      @core.TownEvent::new(
        id="event-supervise-\{directive.task_id}-\{directive.kind}",
        kind="supervision",
        detail=directive.detail,
        related_task_id=Some(directive.task_id),
      ),
    )
    apply_supervision_directive(state, mayor, catalog, directive)
  }
}

///|
async fn reconcile_live_executions(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  let tick = supervision_tick(state)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !live_execution_status(execution.status) {
      continue
    }
    match execution.run_id {
      Some(run_id) => {
        let polled = @moonclaw.poll_run(
          execution.task_id,
          run_id,
          cwd=book_workspace_root(state, execution.book_id),
        )
        let updated = copy_execution_with(
          execution,
          status=polled.status,
          summary=polled.summary,
          heartbeat_tick=tick,
          stale_after_tick=tick + 3,
        )
        state.replace_execution(updated)
        state.replace_task(task_for_supervision(state, updated))
        sync_worker_from_execution(state, updated)
        if updated.status != execution.status &&
          terminal_execution_status(updated.status) {
          state.record_event(
            execution_event(updated, state.executions.length() - 1),
          )
          match @moonbook.entry_for_book_id(catalog, updated.book_id) {
            Some(entry) => persist_execution_into_book(state, entry, updated)
            None => ()
          }
        }
      }
      None => ()
    }
  }
}

///|
fn live_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::ProposalImported => true
    @core.TaskExecutionStatus::RunConfirmed => true
    @core.TaskExecutionStatus::Running => true
    _ => false
  }
}

///|
fn book_workspace_root(state : @core.TownState, book_id : String) -> String {
  for book in state.books {
    if book.id == book_id {
      return book.workspace_root
    }
  }
  "."
}

///|
async fn apply_supervision_directive(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  directive : @roles.MayorSupervisionDirective,
) -> Unit {
  let execution = match @core.find_execution(state, directive.task_id) {
    Some(execution) => execution
    None => return
  }
  match directive.kind {
    "persist-result" =>
      match @moonbook.entry_for_book_id(catalog, execution.book_id) {
        Some(entry) => persist_execution_into_book(state, entry, execution)
        None => ()
      }
    "mark-stale-retry" | "mark-stale-failed" => {
      let updated = copy_execution_with(
        execution,
        status=directive.execution_status,
        summary=directive.detail,
        next_retry_tick=directive.next_retry_tick,
      )
      state.replace_execution(updated)
      state.replace_task(task_for_supervision(state, updated))
      sync_worker_from_execution(state, updated)
    }
    "retry-execution" =>
      retry_execution(state, mayor, catalog, execution, directive)
    "review-sync" => {
      let updated = copy_execution_with(
        execution,
        heartbeat_tick=supervision_tick(state),
      )
      state.replace_execution(updated)
    }
    _ => ()
  }
}

///|
fn task_for_supervision(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> @core.TownTask {
  match @core.find_task(state, execution.task_id) {
    Some(task) => {
      let status = match execution.status {
        @core.TaskExecutionStatus::Completed => @core.TownTaskStatus::Done
        @core.TaskExecutionStatus::Failed => @core.TownTaskStatus::Failed
        @core.TaskExecutionStatus::Stale => @core.TownTaskStatus::Blocked
        @core.TaskExecutionStatus::ReviewQueued => @core.TownTaskStatus::Blocked
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::AwaitingPersistence =>
          @core.TownTaskStatus::Running
        @core.TaskExecutionStatus::PacketReady => @core.TownTaskStatus::Planned
        @core.TaskExecutionStatus::ProposalImported
        | @core.TaskExecutionStatus::RunConfirmed =>
          @core.TownTaskStatus::Assigned
      }
      copy_task_with_status(task, status)
    }
    None =>
      @core.TownTask::new(
        id=execution.task_id,
        book_id=execution.book_id,
        title=execution.task_id,
        prompt=execution.summary,
        domain=@core.WorkDomain::Research,
        status=@core.TownTaskStatus::Blocked,
      )
  }
}

///|
async fn retry_execution(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  execution : @core.TaskExecutionRecord,
  directive : @roles.MayorSupervisionDirective,
) -> Unit {
  let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
    Some(entry) => entry
    None => return
  }
  let task = match @core.find_task(state, execution.task_id) {
    Some(task) => task
    None => return
  }
  let retry_task = @moonbook.BookTask::new(
    id=task.id,
    goal=Some(task.prompt),
    title=task.title,
    kind=stage_kind_for_task(task),
    prompt=task.prompt,
    priority=80,
    requires_review=execution.requires_review,
    required_role=task.required_role,
  )
  let rerun = execute_goal_book_task(
    mayor,
    entry,
    retry_task,
    assigned_worker_id=execution.assigned_worker_id,
    tick=supervision_tick(state),
  ) catch {
    error =>
      failed_execution_record(
        entry,
        retry_task,
        "Mayor retry failed for \{entry.id} / \{task.id}: \{error}",
      )
  }
  let updated = copy_execution_with(
    rerun,
    attempt=execution.attempt + 1,
    next_retry_tick=directive.next_retry_tick,
  )
  state.replace_execution(updated)
  state.replace_task(task_for_supervision(state, updated))
  sync_worker_from_execution(state, updated)
  persist_execution_into_book(state, entry, updated)
}

///|
fn stage_kind_for_task(task : @core.TownTask) -> String {
  let text = "\{task.id} \{task.title} \{task.prompt}".to_lower()
  if text.contains("ingest") || text.contains("source") {
    "ingest"
  } else if text.contains("review") {
    "review"
  } else if text.contains("plan") {
    "planning"
  } else {
    "analysis"
  }
}

///|
fn prioritized_tasks(
  tasks : Array[@moonbook.BookTask],
  goal : String,
) -> Array[@moonbook.BookTask] {
  let ordered = tasks.copy()
  let research_goal = is_research_goal(goal)
  ordered.sort_by(fn(left, right) {
    task_priority_score(right, research_goal).compare(
      task_priority_score(left, research_goal),
    )
  })
  ordered
}

///|
priv struct ResearchBootstrapPlan {
  tasks : Array[@moonbook.BookTask]
  task_limit : Int
  bootstrap_active : Bool
}

///|
async fn research_bootstrap_plan(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  let ordered = prioritized_tasks(tasks, goal)
  let bootstrap_active = research_goal_needs_bootstrap(entry, goal, summary)
  if !bootstrap_active {
    return { tasks: ordered, task_limit, bootstrap_active: false }
  }
  let bootstrap_task = bootstrap_ingest_task(entry, goal)
  let planned = [
    bootstrap_task,
    ..ordered.filter(fn(task) { task.id != bootstrap_task.id }),
  ]
  let effective_limit = research_bootstrap_task_limit()
  { tasks: planned, task_limit: effective_limit, bootstrap_active: true }
}

///|
fn research_bootstrap_task_limit() -> Int {
  1
}

///|
async fn research_goal_needs_bootstrap(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
) -> Bool {
  if !is_research_goal(goal) {
    return false
  }
  let no_substantive_tree = !has_substantive_research_tree(entry)
  let missing_domain_coverage = summary.entity_count == 0 &&
    summary.concept_count == 0
  let no_durable_sources = summary.source_count == 0
  let no_durable_evidence = summary.evidence_count == 0
  no_substantive_tree ||
  missing_domain_coverage ||
  no_durable_sources ||
  no_durable_evidence
}

///|
fn bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  let normalized_goal = goal.trim().to_string()
  @moonbook.BookTask::new(
    id="goal-\{entry.id}-research-bootstrap-ingest",
    goal=Some(normalized_goal),
    title="Bootstrap maintained research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question. Discover the highest-signal sources about \{normalized_goal}, ingest them into the book boundary, populate raw evidence, and revise the maintained wiki so later synthesis can cite durable pages for Moontown, MoonBook, and MoonClaw.",
    priority=100,
    requires_review=true,
    target_pages=[
      "wiki/log.md", "wiki/synthesis/maintenance-plan.md", "wiki/synthesis/evidence.md",
      "raw/README.md",
    ],
    required_role=Some(@core.WorkerRole::Harness),
  )
}

///|
fn is_research_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("research") ||
  notes.contains("moontown") ||
  notes.contains("moonbook") ||
  notes.contains("moonclaw")
}

///|
async fn has_substantive_research_tree(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  let root = @moonbook.workspace_root(entry)
  let paths = [
    "\{root}/wiki/entities",
    "\{root}/wiki/concepts",
    "\{root}/wiki/sources",
    "\{root}/wiki/queries",
  ]
  for path in paths {
    let listed = @integration.run_checked("find", [path, "-type", "f"]) catch {
      _ => continue
    }
    if !listed.stdout.trim().is_blank() {
      return true
    }
  }
  false
}

///|
fn task_priority_score(task : @moonbook.BookTask, research_goal : Bool) -> Int {
  let kind_score = match task.kind {
    "analysis" => 60
    "synthesis" => 50
    "planning" => if research_goal { 15 } else { 40 }
    "review" => if research_goal { 10 } else { 45 }
    "ingest" | "ingest-followup" => if research_goal { 35 } else { 25 }
    _ => 20
  }
  kind_score + task.priority
}
