///|
pub async fn run_goal(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let selected = select_goal_books(catalog, goal, explicit_book_id=book_id)
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  let mayor = demo_mayor()
  register_demo_books(state, @moonbook.catalog_to_book_refs(selected))
  register_demo_workers(state)
  state.record_event(
    @core.TownEvent::new(
      id="event-goal",
      kind="goal",
      detail="Accepted town goal: \{goal}",
    ),
  )
  let limit = if task_limit_per_book < 1 { 1 } else { task_limit_per_book }
  for entry in selected {
    run_goal_for_book(state, mayor, entry, goal, limit)
  }
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
async fn run_goal_for_book(
  state : @core.TownState,
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  task_limit : Int,
) -> Unit {
  let acceptance = @moonbook.accept_goal(entry, goal) catch {
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
  let batch = @moonbook.produce_task_batch(entry, goal) catch {
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
    goal,
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
    let execution = execute_goal_book_task(mayor, entry, task) catch {
      error =>
        failed_execution_record(
          entry,
          task,
          "Goal execution failed for \{entry.id} / \{task.id}: \{error}",
        )
    }
    state.enqueue_task(to_town_task(entry, task, execution.status))
    state.register_execution(execution)
    state.record_event(
      execution_event(execution, state.executions.length() - 1),
    )
    persist_execution_into_book(state, entry, execution)
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
  Some((wait_for_terminal_run(task_id, run_id, workspace_root), launch_command))
}

///|
async fn wait_for_terminal_run(
  task_id : String,
  run_id : String,
  workspace_root : String,
  max_attempts? : Int = 90,
  sleep_ms? : Int = 1000,
) -> @moonclaw.ProposalPollResponse {
  let mut last = @moonclaw.poll_run(task_id, run_id, cwd=workspace_root)
  let attempts = if max_attempts < 1 { 1 } else { max_attempts }
  for _ in 0..<attempts {
    if terminal_execution_status(last.status) {
      return last
    }
    @async.sleep(sleep_ms)
    last = @moonclaw.poll_run(task_id, run_id, cwd=workspace_root)
  }
  last
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
    @core.TaskExecutionStatus::Failed => true
    _ => false
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
  let effective_limit = if task_limit < 2 { 2 } else { task_limit }
  { tasks: planned, task_limit: effective_limit, bootstrap_active: true }
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

///|
fn select_goal_books(
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
  explicit_book_id? : String? = None,
) -> Array[@moonbook.BookCatalogEntry] {
  match explicit_book_id {
    Some(book_id) =>
      match @moonbook.find_catalog_entry(catalog, book_id) {
        Some(entry) => [entry]
        None => []
      }
    None => {
      let notes = goal.to_lower()
      let chosen = if notes.contains("finance") ||
        notes.contains("ledger") ||
        notes.contains("budget") ||
        notes.contains("daily") {
        @moonbook.find_catalog_entry(catalog, "finance")
      } else {
        @moonbook.find_catalog_entry(catalog, "coding")
      }
      match chosen {
        Some(entry) => [entry]
        None => if catalog.is_empty() { [] } else { [catalog[0]] }
      }
    }
  }
}
