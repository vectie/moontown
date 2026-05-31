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
    @core.TaskExecutionStatus::ReviewQueued => @core.WorkerStatus::Idle
    @core.TaskExecutionStatus::Completed => @core.WorkerStatus::Idle
    @core.TaskExecutionStatus::Stale => @core.WorkerStatus::Blocked
    @core.TaskExecutionStatus::Failed => @core.WorkerStatus::Idle
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
  context_pages? : Array[String] = execution.context_pages,
  skill_paths? : Array[String] = execution.skill_paths,
  result_decision? : String = execution.result_decision,
  requires_review? : Bool = execution.requires_review,
  notify_town? : Bool = execution.notify_town,
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
    context_pages~,
    skill_paths~,
    last_command=execution.last_command,
    assigned_worker_id=execution.assigned_worker_id,
    attempt~,
    heartbeat_tick~,
    stale_after_tick~,
    next_retry_tick~,
    result_decision~,
    requires_review~,
    notify_town~,
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
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goals? : Array[@core.StandingGoal] = [],
) -> Unit {
  reconcile_live_executions(state, catalog, snapshot_path, standing_goals)
  reconcile_review_queued_standing_watch_outputs(
    state, catalog, snapshot_path, standing_goals,
  )
  reconcile_failed_standing_watch_outputs(
    state, catalog, snapshot_path, standing_goals,
  )
  reconcile_persisted_non_review_outputs(state, snapshot_path)
  reconcile_persisted_terminal_outputs(state, snapshot_path)
  reconcile_repaired_context_import_failures(state)
  release_orphaned_blocked_workers(state)
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
    if directive.kind == "retry-execution" &&
      live_external_execution_count(state) >= max_live_external_executions() {
      state.record_event(
        @core.TownEvent::new(
          id="event-supervise-\{directive.task_id}-retry-deferred-cap",
          kind="supervision",
          detail="Mayor deferred retry for \{directive.task_id} because live external execution count reached \{max_live_external_executions()}.",
          related_task_id=Some(directive.task_id),
        ),
      )
      continue
    }
    state.record_event(
      @core.TownEvent::new(
        id="event-supervise-\{directive.task_id}-\{directive.kind}",
        kind="supervision",
        detail=directive.detail,
        related_task_id=Some(directive.task_id),
      ),
    )
    apply_supervision_directive(
      state, mayor, catalog, directive, snapshot_path, standing_goals,
    )
  }
}

///|
async fn reconcile_repaired_context_import_failures(
  state : @core.TownState,
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != @core.TaskExecutionStatus::Failed ||
      !execution.summary.contains("context_pages must not be empty") {
      continue
    }
    match @moonclaw.load_packet_file(execution.packet_path) {
      Some(packet) if packet.context_pages.length() > 0 => {
        let completed = copy_execution_with(
          execution,
          status=@core.TaskExecutionStatus::Completed,
          summary="\{execution.summary}\nkeeper_auto_triage: superseded_context_import_failure\nreconciled_detail: referenced packet now has \{packet.context_pages.length()} context page(s), so the stale import-validation failure no longer represents active work.",
          context_pages=packet.context_pages,
          skill_paths=packet.skill_paths,
          heartbeat_tick=supervision_tick(state),
          next_retry_tick=None,
          result_decision="superseded",
          requires_review=false,
          notify_town=false,
        )
        state.replace_execution(completed)
        state.replace_task(task_for_supervision(state, completed))
        sync_worker_from_execution(state, completed)
        state.record_event(
          @core.TownEvent::new(
            id="event-repaired-context-import-\{state.events.length()}-\{completed.task_id}",
            kind="recovery",
            detail="Mayor reconciled stale import failure `\{completed.task_id}` because the saved packet now contains keeper context.",
            related_task_id=Some(completed.task_id),
            related_book_id=Some(completed.book_id),
            related_run_id=completed.run_id,
          ),
        )
      }
      _ => ()
    }
  }
}

///|
fn live_external_execution_count(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    match execution.status {
      @core.TaskExecutionStatus::ProposalImported
      | @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running =>
        if execution.run_id is Some(_) {
          count += 1
        }
      _ => ()
    }
  }
  count
}

///|
fn max_live_external_executions() -> Int {
  8
}

///|
async fn reconcile_persisted_non_review_outputs(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != @core.TaskExecutionStatus::ReviewQueued {
      continue
    }
    match persisted_non_review_book_result(snapshot_path, execution.task_id) {
      Some(result) => {
        let completed = copy_execution_with(
          execution,
          status=@core.TaskExecutionStatus::Completed,
          summary="\{execution.summary}\nkeeper_auto_triage: persisted_non_review_result\npersisted_result_summary: \{result.summary}",
          heartbeat_tick=supervision_tick(state),
          next_retry_tick=None,
        )
        state.replace_execution(completed)
        state.replace_task(task_for_supervision(state, completed))
        sync_worker_from_execution(state, completed)
        state.record_event(
          @core.TownEvent::new(
            id="event-persisted-non-review-\{state.events.length()}-\{completed.task_id}",
            kind="review",
            detail="Mayor closed review queue for `\{completed.task_id}` because MoonBook already persisted a non-review result.",
            related_task_id=Some(completed.task_id),
            related_book_id=Some(completed.book_id),
            related_run_id=completed.run_id,
          ),
        )
      }
      None => ()
    }
  }
}

///|
async fn reconcile_persisted_terminal_outputs(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != @core.TaskExecutionStatus::Failed &&
      execution.status != @core.TaskExecutionStatus::Stale &&
      execution.status != @core.TaskExecutionStatus::AwaitingPersistence {
      continue
    }
    match persisted_book_result(snapshot_path, execution.task_id) {
      Some(result) => {
        let outcome : @moonbook.PersistResultOutcome = @json.from_json(
          @json.parse(
            "{\"log_path\":\"\",\"updated_pages\":[],\"review_queued\":\{result.requires_review},\"notify_town\":\{result.notify_town},\"evidence_id\":\"persisted-book-result\"}",
          ),
        )
        let reconciled = execution_after_successful_book_persist(
          execution,
          outcome,
          supervision_tick(state),
        )
        if reconciled != execution {
          state.replace_execution(reconciled)
          state.replace_task(task_for_supervision(state, reconciled))
          sync_worker_from_execution(state, reconciled)
          state.record_event(
            @core.TownEvent::new(
              id="event-persisted-terminal-\{state.events.length()}-\{reconciled.task_id}",
              kind="recovery",
              detail="Mayor reconciled `\{reconciled.task_id}` because MoonBook already has a persisted terminal result.",
              related_task_id=Some(reconciled.task_id),
              related_book_id=Some(reconciled.book_id),
              related_run_id=reconciled.run_id,
            ),
          )
        }
      }
      None => ()
    }
  }
}

///|
async fn persisted_non_review_book_result(
  snapshot_path : String,
  task_id : String,
) -> @moonbook.BookResult? {
  match persisted_book_result(snapshot_path, task_id) {
    Some(result) if !result.requires_review => Some(result)
    _ => None
  }
}

///|
async fn persisted_book_result(
  snapshot_path : String,
  task_id : String,
) -> @moonbook.BookResult? {
  let path = book_result_path_for_snapshot(snapshot_path, task_id)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  let result : @moonbook.BookResult = @json.from_json(parsed) catch {
    _ => return None
  }
  Some(result)
}

///|
fn book_result_path_for_snapshot(
  snapshot_path : String,
  task_id : String,
) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  let root = if base == "." || base == "" { ".moontown" } else { base }
  "\{root}/book-results/\{task_id}.json"
}

///|
fn release_orphaned_blocked_workers(state : @core.TownState) -> Unit {
  let workers = state.workers.copy()
  for worker in workers {
    if worker.status == @core.WorkerStatus::Idle ||
      worker.status == @core.WorkerStatus::Offline {
      continue
    }
    match latest_execution_for_worker(state, worker.id) {
      Some(execution) if worker_should_be_released(execution) => {
        state.set_worker_status(worker.id, @core.WorkerStatus::Idle)
        state.record_event(
          @core.TownEvent::new(
            id="event-worker-release-\{state.events.length()}-\{worker.id}",
            kind="recovery",
            detail="Mayor released blocked worker \{worker.id} after terminal execution \{execution.task_id} reached \{execution.status.to_string()}.",
            related_task_id=Some(execution.task_id),
            related_book_id=Some(execution.book_id),
            related_run_id=execution.run_id,
          ),
        )
      }
      None => {
        state.set_worker_status(worker.id, @core.WorkerStatus::Idle)
        state.record_event(
          @core.TownEvent::new(
            id="event-worker-release-\{state.events.length()}-\{worker.id}",
            kind="recovery",
            detail="Mayor released non-idle worker \{worker.id} because no live or terminal execution still owns it.",
          ),
        )
      }
      _ => ()
    }
  }
}

///|
fn latest_execution_for_worker(
  state : @core.TownState,
  worker_id : String,
) -> @core.TaskExecutionRecord? {
  let mut latest : @core.TaskExecutionRecord? = None
  for execution in state.executions {
    match execution.assigned_worker_id {
      Some(id) if id == worker_id => latest = Some(execution)
      _ => ()
    }
  }
  latest
}

///|
fn worker_should_be_released(execution : @core.TaskExecutionRecord) -> Bool {
  match execution.status {
    @core.TaskExecutionStatus::Completed => true
    @core.TaskExecutionStatus::ReviewQueued => true
    @core.TaskExecutionStatus::Failed => true
    @core.TaskExecutionStatus::Stale => true
    _ => false
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
    run_supervision_cycle(state, mayor, catalog, snapshot_path~)
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
      @core.TaskExecutionStatus::Stale
      | @core.TaskExecutionStatus::Failed
      | @core.TaskExecutionStatus::ReviewQueued =>
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
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
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
          stale_after_tick=tick + polled_execution_stale_window_ticks(execution),
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
            Some(entry) => {
              let reconciled = match
                persist_execution_into_book(state, entry, updated) {
                Some(outcome) =>
                  execution_after_successful_book_persist(
                    updated,
                    outcome,
                    supervision_tick(state),
                  )
                None => updated
              }
              if reconciled != updated {
                state.replace_execution(reconciled)
                state.replace_task(task_for_supervision(state, reconciled))
                sync_worker_from_execution(state, reconciled)
              }
              finalize_goal_book_entry(state, entry, 0, [reconciled.task_id])
              let observed = finalize_standing_watch_supervision_record(
                state, entry, reconciled, standing_goals, snapshot_path,
              )
              if observed != reconciled {
                state.replace_execution(observed)
                state.replace_task(task_for_supervision(state, observed))
                sync_worker_from_execution(state, observed)
              }
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
fn polled_execution_stale_window_ticks(
  execution : @core.TaskExecutionRecord,
) -> Int {
  match execution.run_id {
    Some(_) => 30
    None => 3
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
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let execution = match @core.find_execution(state, directive.task_id) {
    Some(execution) => execution
    None => return
  }
  match directive.kind {
    "persist-result" =>
      match @moonbook.entry_for_book_id(catalog, execution.book_id) {
        Some(entry) =>
          match persist_execution_into_book(state, entry, execution) {
            Some(outcome) => {
              let reconciled = execution_after_successful_book_persist(
                execution,
                outcome,
                supervision_tick(state),
              )
              if reconciled != execution {
                state.replace_execution(reconciled)
                state.replace_task(task_for_supervision(state, reconciled))
                sync_worker_from_execution(state, reconciled)
              }
            }
            None => ()
          }
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
      retry_execution(
        state, mayor, catalog, execution, directive, snapshot_path, standing_goals,
      )
    "review-sync" => {
      let updated = copy_execution_with(
        execution,
        heartbeat_tick=supervision_tick(state),
      )
      state.replace_execution(updated)
      sync_worker_from_execution(state, updated)
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
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
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
        assigned_worker_id=execution.assigned_worker_id,
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
  let reconciled = match persist_execution_into_book(state, entry, updated) {
    Some(outcome) =>
      execution_after_successful_book_persist(
        updated,
        outcome,
        supervision_tick(state),
      )
    None => updated
  }
  if reconciled != updated {
    state.replace_execution(reconciled)
    state.replace_task(task_for_supervision(state, reconciled))
    sync_worker_from_execution(state, reconciled)
  }
  if terminal_execution_status(updated.status) {
    finalize_goal_book_entry(state, entry, 0, [reconciled.task_id])
    let observed = finalize_standing_watch_supervision_record(
      state, entry, reconciled, standing_goals, snapshot_path,
    )
    if observed != reconciled {
      state.replace_execution(observed)
      state.replace_task(task_for_supervision(state, observed))
      sync_worker_from_execution(state, observed)
    }
  }
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
