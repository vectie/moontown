///|
fn supervision_tick(state : @core.TownState) -> Int {
  state.events.length() + state.executions.length() + 1
}

///|
fn resolved_supervision_tick(state : @core.TownState, tick : Int?) -> Int {
  let fallback = supervision_tick(state)
  match tick {
    Some(value) => @support.max_int(fallback, value)
    None => fallback
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
  packet_id? : String = execution.packet_id,
  packet_path? : String = execution.packet_path,
  proposal_id? : String? = execution.proposal_id,
  run_id? : String? = execution.run_id,
  result_decision? : String = execution.result_decision,
  requires_review? : Bool = execution.requires_review,
  notify_town? : Bool = execution.notify_town,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id=execution.task_id,
    book_id=execution.book_id,
    packet_id~,
    packet_path~,
    proposal_id~,
    run_id~,
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
fn book_workspace_root(state : @core.TownState, book_id : String) -> String {
  for book in state.books {
    if book.id == book_id {
      return book.workspace_root
    }
  }
  "."
}

///|
fn task_for_supervision(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> @core.TownTask {
  match @core.find_task(state, execution.task_id) {
    Some(task) =>
      @core.copy_task_with_status(
        task,
        @core.town_task_status_for_execution(execution.status),
      )
    None =>
      @core.TownTask::new(
        id=execution.task_id,
        book_id=execution.book_id,
        title=execution.task_id,
        prompt=execution.summary,
        domain=Research,
        status=Blocked,
      )
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
