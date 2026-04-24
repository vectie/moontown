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
  refresh_live_execution_deadlines(state)
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
fn refresh_live_execution_deadlines(state : @core.TownState) -> Unit {
  let tick = supervision_tick(state)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if live_execution_status(execution.status) {
      state.replace_execution(
        copy_execution_with(
          execution,
          heartbeat_tick=tick,
          stale_after_tick=tick + 3,
        ),
      )
    }
  }
}

///|
async fn wait_for_goal_settle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  max_cycles? : Int = 120,
  sleep_ms? : Int = 5_000,
) -> Unit {
  let cycles = if max_cycles < 1 { 1 } else { max_cycles }
  for cycle = 0; cycle < cycles; cycle = cycle + 1 {
    run_supervision_cycle(state, mayor, catalog)
    persist_town_checkpoint(state, snapshot_path)
    if !has_live_executions(state) &&
      !has_retry_pending_executions(state, supervision_tick(state)) {
      return
    }
    @async.sleep(sleep_ms)
  }
  if has_live_executions(state) {
    state.record_event(
      @core.TownEvent::new(
        id="event-settle-timeout-\{supervision_tick(state)}",
        kind="supervision",
        detail="Mayor supervision timed out while waiting for live executions to settle.",
      ),
    )
  }
}

///|
fn has_live_executions(state : @core.TownState) -> Bool {
  for execution in state.executions {
    if live_execution_status(execution.status) {
      return true
    }
  }
  false
}

///|
fn has_retry_pending_executions(state : @core.TownState, tick : Int) -> Bool {
  ignore(tick)
  for execution in state.executions {
    match execution.status {
      @core.TaskExecutionStatus::Stale | @core.TaskExecutionStatus::Failed =>
        match execution.next_retry_tick {
          Some(_) if execution.attempt < 3 => return true
          _ => ()
        }
      _ => ()
    }
  }
  false
}

///|
async fn reconcile_live_executions(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  let tick = supervision_tick(state)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !pollable_execution_status(execution.status) {
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
        if execution.status is @core.TaskExecutionStatus::Stale &&
          !terminal_execution_status(polled.status) {
          continue
        }
        state.replace_execution(updated)
        state.replace_task(task_for_supervision(state, updated))
        sync_worker_from_execution(state, updated)
        if updated.status != execution.status &&
          terminal_execution_status(updated.status) {
          state.record_event(
            execution_event(updated, state.executions.length() - 1),
          )
          match @moonbook.entry_for_book_id(catalog, updated.book_id) {
            Some(entry) => {
              persist_execution_into_book(state, entry, updated)
              finalize_goal_book_entry(state, entry, 0, [updated.task_id])
            }
            None => ()
          }
        }
      }
      None => ()
    }
  }
}

///|
fn pollable_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  live_execution_status(status) || status is @core.TaskExecutionStatus::Stale
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
