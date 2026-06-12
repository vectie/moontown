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
    if @core.live_external_execution_count(state) >=
      @core.max_live_external_executions() {
      queue_goal_book_task(state, launch.entry, task, planned_task, tick)
      continue
    }
    launch_goal_book_task(
      state,
      mayor,
      launch.entry,
      task,
      planned_task,
      tick,
      launch.pending_review_baseline,
    )
  }
}

///|
async fn launch_goal_book_task(
  state : @core.TownState,
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  planned_task : @core.TownTask,
  tick : Int,
  pending_review_baseline : Int,
) -> Unit {
  let decision = mayor.decide_dispatch(state, planned_task)
  state.record_event(route_event(decision.decision, state.events.length()))
  let worker_id = assigned_worker_id(decision.decision)
  let execution = execute_goal_book_task(
    mayor,
    entry,
    task,
    assigned_worker_id=worker_id,
    tick~,
  ) catch {
    error =>
      failed_execution_record(
        entry,
        task,
        "Goal execution failed for \{entry.id} / \{task.id}: \{error}",
        assigned_worker_id=worker_id,
      )
  }
  let completed_execution = @build_pipeline.complete_wenyu_build_artifacts_if_needed(
    entry, task, execution,
  )
  record_goal_execution(state, entry, task, completed_execution)
  let reconciled_execution = match
    persist_execution_into_book(state, entry, completed_execution) {
    Some(outcome) =>
      execution_after_successful_book_persist(
        completed_execution, outcome, tick,
      )
    None => completed_execution
  }
  if reconciled_execution != completed_execution {
    record_goal_execution(state, entry, task, reconciled_execution)
  }
  if @core.terminal_execution_status(completed_execution.status) {
    finalize_goal_book_entry(state, entry, pending_review_baseline, [
      reconciled_execution.task_id,
    ])
  }
}

///|
fn queue_goal_book_task(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  planned_task : @core.TownTask,
  tick : Int,
) -> Unit {
  let queued_execution = queued_goal_execution_record(
    entry,
    task,
    tick,
    "Mayor queued \{task.id} because live external execution count reached \{@core.max_live_external_executions()}; the supervision loop will launch it when capacity is available.",
  )
  state.replace_task(planned_task)
  state.replace_execution(queued_execution)
  state.record_event(
    @core.TownEvent::new(
      id="event-queue-\{state.events.length()}-\{task.id}",
      kind="execution-queue",
      detail=queued_execution.summary,
      related_task_id=Some(task.id),
      related_book_id=Some(entry.id),
    ),
  )
}

///|
fn record_goal_execution(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  state.replace_task(to_town_task(entry, task, execution.status))
  state.replace_execution(execution)
  sync_worker_from_execution(state, execution)
  state.record_event(execution_event(execution, state.executions.length() - 1))
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
