///|
fn route_event(
  decision : @dispatch.RouteDecision,
  index : Int,
) -> @core.TownEvent {
  match decision {
    Assigned(plan) =>
      @core.TownEvent::new(
        id="event-route-\{index}",
        kind="assignment",
        detail="\{plan.task_id} -> \{plan.worker_id} (\{plan.reason})",
        related_task_id=Some(plan.task_id),
        related_book_id=Some(plan.book_id),
      )
    Escalated(reason) =>
      @core.TownEvent::new(
        id="event-route-\{index}",
        kind="escalation",
        detail=reason,
      )
    Deferred(reason) =>
      @core.TownEvent::new(
        id="event-route-\{index}",
        kind="deferred",
        detail=reason,
      )
  }
}

///|
fn execution_event(
  execution : @core.TaskExecutionRecord,
  index : Int,
) -> @core.TownEvent {
  let proposal = execution.proposal_id.unwrap_or("draft")
  @core.TownEvent::new(
    id="event-exec-\{index}",
    kind="execution",
    detail="\{execution.task_id} -> \{execution.status.to_string()} / proposal=\{proposal}",
    related_task_id=Some(execution.task_id),
    related_book_id=Some(execution.book_id),
    related_proposal_id=execution.proposal_id,
    related_run_id=execution.run_id,
  )
}

///|
fn register_demo_books(
  state : @core.TownState,
  books : Array[@core.BookRef],
) -> Unit {
  for book in books {
    state.register_book(book)
  }
}

///|
fn register_demo_workers(state : @core.TownState) -> Unit {
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Hound",
      book_id="coding",
      role=@core.WorkerRole::Harness,
      capabilities=["moonbit", "git", "testing"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=@core.WorkerRole::Reviewer,
      capabilities=["review", "moonbit"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=@core.WorkerRole::Specialist,
      capabilities=["ledgers", "reporting"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=@core.WorkerRole::MemoryKeeper,
      capabilities=["reporting", "planning"],
    ),
  )
}

///|
fn domain_for_book(entry : @moonbook.BookCatalogEntry) -> @core.WorkDomain {
  match entry.id {
    "finance" => @core.WorkDomain::Finance
    "coding" => @core.WorkDomain::Coding
    _ => @core.WorkDomain::Operations
  }
}

///|
fn execution_status_for_index(index : Int) -> @core.TaskExecutionStatus {
  match index {
    0 => @core.TaskExecutionStatus::ProposalImported
    1 => @core.TaskExecutionStatus::Running
    2 => @core.TaskExecutionStatus::AwaitingPersistence
    3 => @core.TaskExecutionStatus::ReviewQueued
    _ => @core.TaskExecutionStatus::PacketReady
  }
}

///|
fn town_task_status_for_execution(
  status : @core.TaskExecutionStatus,
) -> @core.TownTaskStatus {
  match status {
    @core.TaskExecutionStatus::PacketReady => @core.TownTaskStatus::Planned
    @core.TaskExecutionStatus::ProposalImported =>
      @core.TownTaskStatus::Assigned
    @core.TaskExecutionStatus::RunConfirmed => @core.TownTaskStatus::Assigned
    @core.TaskExecutionStatus::Running => @core.TownTaskStatus::Running
    @core.TaskExecutionStatus::AwaitingPersistence =>
      @core.TownTaskStatus::Running
    @core.TaskExecutionStatus::ReviewQueued => @core.TownTaskStatus::Blocked
    @core.TaskExecutionStatus::Completed => @core.TownTaskStatus::Done
    @core.TaskExecutionStatus::Failed => @core.TownTaskStatus::Failed
  }
}

///|
fn synthetic_execution_record(
  task : @core.TownTask,
  index : Int,
) -> @core.TaskExecutionRecord {
  let status = execution_status_for_index(index)
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=task.book_id,
    packet_id="packet-\{task.id}",
    packet_path=".moontown/packets/packet-\{task.id}.json",
    proposal_id=Some("proposal-packet-\{task.id}"),
    run_id=if status == @core.TaskExecutionStatus::ProposalImported {
      None
    } else {
      Some("run-packet-\{task.id}")
    },
    status~,
    summary="Synthetic lifecycle for \{task.id}",
    output_contract="keeper.plan.packet.v1",
    context_pages=["wiki/index.md", "wiki/log.md"],
    skill_paths=["skills/wiki-maintainer/SKILL.md"],
    requires_review=status == @core.TaskExecutionStatus::ReviewQueued,
    notify_town=true,
  )
}

///|
fn append_routes_and_events(state : @core.TownState) -> Unit {
  for i in 0..<state.tasks.length() {
    let task = state.tasks[i]
    let decision = @dispatch.route_task(
      state,
      @dispatch.RouteRequest::new(task~),
    )
    state.record_event(route_event(decision, i))
  }
  for i in 0..<state.executions.length() {
    state.record_event(execution_event(state.executions[i], i))
  }
}

///|
fn goal_for_book(entry : @moonbook.BookCatalogEntry) -> String {
  match entry.id {
    "coding" =>
      "Plan next coding revisions, review the protocol, and keep harness memory healthy."
    "finance" =>
      "Refresh finance memory, review the ledger workflow, and prepare the next brief."
    _ => "Maintain the book and produce a keeper-ready domain summary."
  }
}

///|
fn fixture_book_tasks(
  entry : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookTask] {
  let goal = goal_for_book(entry)
  match entry.id {
    "coding" =>
      [
        @moonbook.BookTask::new(
          id="goal-plan-next-coding-review",
          goal=Some(goal),
          title="Review pending book updates",
          kind="review",
          prompt="Review pending changes for the goal inside \{entry.name}: \{goal}",
          priority=100,
          requires_review=false,
          target_pages=["wiki/reviews/pending.md", "wiki/reviews/approved.md"],
          required_role=Some(@core.WorkerRole::Reviewer),
        ),
        @moonbook.BookTask::new(
          id="goal-plan-next-coding-planning",
          goal=Some(goal),
          title="Refresh local planning surfaces",
          kind="planning",
          prompt="Plan the next book-local revisions for the goal inside \{entry.name}: \{goal}",
          priority=95,
          requires_review=true,
          target_pages=[
            "wiki/synthesis/maintenance-plan.md", "wiki/synthesis/map.md",
          ],
          required_role=Some(@core.WorkerRole::Planner),
        ),
      ]
    "finance" =>
      [
        @moonbook.BookTask::new(
          id="goal-refresh-finance-memory-review",
          goal=Some(goal),
          title="Review pending book updates",
          kind="review",
          prompt="Review pending changes for the goal inside \{entry.name}: \{goal}",
          priority=100,
          requires_review=false,
          target_pages=["wiki/reviews/pending.md", "wiki/reviews/approved.md"],
          required_role=Some(@core.WorkerRole::Reviewer),
        ),
        @moonbook.BookTask::new(
          id="goal-refresh-finance-memory-analysis",
          goal=Some(goal),
          title="Produce domain-local task result",
          kind="analysis",
          prompt="Use the durable wiki and keeper memory in \{entry.name} without leaking to other books: \{goal}",
          priority=85,
          requires_review=true,
          target_pages=["wiki/index.md", "wiki/log.md", "keeper/INSIGHTS.md"],
          required_role=Some(@core.WorkerRole::MemoryKeeper),
        ),
      ]
    _ =>
      [
        @moonbook.BookTask::new(
          id="goal-\{entry.id}-analysis",
          goal=Some(goal),
          title="Produce domain-local task result",
          kind="analysis",
          prompt="Maintain the isolated book state for \{entry.name}: \{goal}",
          priority=80,
          requires_review=true,
          target_pages=["wiki/index.md", "wiki/log.md"],
          required_role=Some(@core.WorkerRole::Harness),
        ),
      ]
  }
}

///|
fn desired_task_count(entry : @moonbook.BookCatalogEntry) -> Int {
  match entry.id {
    "coding" => 2
    "finance" => 2
    _ => 1
  }
}

///|
fn to_town_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  status : @core.TaskExecutionStatus,
) -> @core.TownTask {
  @core.TownTask::new(
    id=task.id,
    book_id=entry.id,
    title=task.title,
    prompt=task.prompt,
    domain=domain_for_book(entry),
    required_role=task.required_role,
    required_capabilities=entry.skills,
    status=town_task_status_for_execution(status),
  )
}

///|
fn seed_catalog_tasks(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  let mut index = 0
  for entry in catalog {
    let limit = desired_task_count(entry)
    let mut emitted = 0
    for task in fixture_book_tasks(entry) {
      if emitted >= limit {
        break
      }
      let execution_status = execution_status_for_index(index)
      let town_task = to_town_task(entry, task, execution_status)
      state.enqueue_task(town_task)
      state.register_execution(synthetic_execution_record(town_task, index))
      emitted += 1
      index += 1
    }
  }
}

///|
async fn live_execution_record_for_book_task(
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> @core.TaskExecutionRecord {
  let prepared = mayor.prepare_keeper_packet(entry, task)
  let imported = @moonclaw.import_packet(
    prepared.packet,
    prepared.packet_path,
    cwd=entry.workspace_root,
    confirm=true,
  )
  let execution_command = match imported.run_id {
    Some(run_id) => {
      let initial = @moonclaw.poll_run(
        task.id,
        run_id,
        cwd=entry.workspace_root,
      )
      if initial.status is @core.TaskExecutionStatus::RunConfirmed {
        Some(@moonclaw.run_confirmed_run(run_id, cwd=entry.workspace_root))
      } else {
        None
      }
    }
    None => None
  }
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id=prepared.packet.packet_id,
    packet_path=prepared.packet_path,
    proposal_id=Some(imported.proposal_id),
    run_id=imported.run_id,
    status=imported.status,
    summary=imported.summary,
    output_contract=prepared.packet.output_contract,
    context_pages=prepared.packet.context_pages,
    skill_paths=prepared.packet.skill_paths,
    last_command=Some(
      match execution_command {
        Some(command) => "\{imported.command}\n\{command}"
        None => imported.command
      },
    ),
    requires_review=task.requires_review,
    notify_town=true,
  )
}

///|
fn failed_execution_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  detail : String,
) -> @core.TaskExecutionRecord {
  let packet_id = "keeper-\{entry.id}-\{task.id}"
  let packet_path = @moonclaw.packet_file_path(
    @moonclaw.default_packet_directory(),
    packet_id,
  )
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id~,
    packet_path~,
    status=@core.TaskExecutionStatus::Failed,
    summary=detail,
    output_contract="keeper.plan.packet.v1",
    requires_review=task.requires_review,
    notify_town=true,
  )
}

///|
async fn build_live_state_from_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  let mayor = demo_mayor()
  register_demo_books(state, @moonbook.catalog_to_book_refs(catalog))
  register_demo_workers(state)
  for entry in catalog {
    let batch = @moonbook.produce_task_batch(entry, goal_for_book(entry)) catch {
      error => {
        let task = fixture_book_tasks(entry)[0]
        let failed_task = to_town_task(
          entry,
          task,
          @core.TaskExecutionStatus::Failed,
        )
        state.enqueue_task(failed_task)
        state.register_execution(
          failed_execution_record(
            entry,
            task,
            "MoonBook task planning failed for \{entry.id}: \{error}",
          ),
        )
        continue
      }
    }
    let limit = desired_task_count(entry)
    let mut emitted = 0
    for task in batch.tasks {
      if emitted >= limit {
        break
      }
      let execution = live_execution_record_for_book_task(mayor, entry, task) catch {
        error =>
          failed_execution_record(
            entry,
            task,
            "Runtime handoff failed for \{entry.id} / \{task.id}: \{error}",
          )
      }
      let town_task = to_town_task(entry, task, execution.status)
      state.enqueue_task(town_task)
      state.register_execution(execution)
      emitted += 1
    }
  }
  append_routes_and_events(state)
  state
}

///|
fn snapshot_requires_refresh(snapshot : @storage.TownSnapshot) -> Bool {
  snapshot.town.books.any(fn(book : @core.BookRef) {
    book.workspace_root.contains("/workspace/")
  }) ||
  snapshot.town.executions.any(fn(execution : @core.TaskExecutionRecord) {
    execution.summary.contains("Synthetic lifecycle") ||
    execution.summary.contains("No such file or directory") ||
    execution.summary.contains("metadata must be object") ||
    execution.summary.contains("Unknown external proposal profile")
  })
}

///|
pub fn demo_state_from_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  register_demo_books(state, @moonbook.catalog_to_book_refs(catalog))
  register_demo_workers(state)
  seed_catalog_tasks(state, catalog)
  append_routes_and_events(state)
  state
}

///|
pub fn[Provider : @core.BookProvider] demo_state_with_provider(
  provider : Provider,
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  register_demo_books(state, provider.books())
  register_demo_workers(state)
  let mut index = 0
  for book in state.books {
    let task = @core.TownTask::new(
      id="task-\{book.id}-overview",
      book_id=book.id,
      title="Book overview for \{book.name}",
      prompt="Summarize the current state for \{book.name}.",
      domain=match book.id {
        "finance" => @core.WorkDomain::Finance
        _ => @core.WorkDomain::Coding
      },
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=book.tags,
      status=town_task_status_for_execution(execution_status_for_index(index)),
    )
    state.enqueue_task(task)
    state.register_execution(synthetic_execution_record(task, index))
    index += 1
  }
  append_routes_and_events(state)
  state
}

///|
pub fn demo_mayor() -> @roles.Mayor {
  @roles.Mayor::new()
}

///|
pub fn demo_state() -> @core.TownState {
  demo_state_from_catalog(@moonbook.default_catalog())
}

///|
pub fn demo_dashboard() -> String {
  render_state_dashboard(demo_state())
}

///|
pub async fn load_or_create_demo_state(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  match @storage.load_snapshot_file(path) {
    Some(snapshot) if !snapshot_requires_refresh(snapshot) => snapshot.town
    _ => {
      let town = build_live_state_from_catalog(catalog)
      @storage.save_snapshot_file(path, @storage.snapshot_of(town))
      town
    }
  }
}

///|
pub async fn load_or_create_modeled_demo_state(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let snapshot = @storage.load_or_create_snapshot(path, () => {
    demo_state_from_catalog(catalog)
  })
  snapshot.town
}

///|
pub async fn[Provider : @core.BookProvider] load_or_create_demo_state_with_provider(
  provider : Provider,
  path? : String = @storage.default_snapshot_path(),
) -> @core.TownState {
  let snapshot = @storage.load_or_create_snapshot(path, () => {
    demo_state_with_provider(provider)
  })
  snapshot.town
}

///|
pub async fn load_or_create_demo_dashboard(
  path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let state = load_or_create_demo_state(path~, book_catalog_path~)
  render_state_dashboard(state)
}

///|
pub fn render_state_dashboard(state : @core.TownState) -> String {
  let mayor = demo_mayor()
  let report = @health.inspect_town(state)
  let model = @ui.build_dashboard(state, report)
  let tick = @scheduler.next_tick(1, @scheduler.plan_tick(state, report))
  let snapshot = @storage.snapshot_of(state)
  let runtime = mayor.runtime()
  let mayor_block = "## Mayor\n- role: \{runtime.role_id}\n- mode: \{runtime.runtime_mode.to_string()}\n- tools: \{runtime.tool_access.to_string()}\n- scope: \{runtime.authority_scope}\n- proposal lifecycle records: \{state.executions.length()}\n\n"
  let recent_events = if state.events.is_empty() {
    "## Events\n- none\n\n"
  } else {
    let builder = StringBuilder::new()
    builder.write_string("## Events\n")
    for event in state.events {
      builder.write_string("- [\{event.kind}] \{event.detail}\n")
    }
    builder.write_string("\n")
    builder.to_string()
  }
  @ui.render_dashboard(model) +
  "\n" +
  mayor_block +
  recent_events +
  "Town Tick\n- \{tick.summary}\n\nSnapshot\n- \{@storage.describe_snapshot(snapshot)}\n"
}
