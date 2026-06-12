///|
fn is_wenyu_book(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.id.has_prefix("wenyu-")
}

///|
fn wenyu_module_name(entry : @moonbook.BookCatalogEntry) -> String {
  let prefix = "Wenyu Valley / "
  if entry.name.has_prefix(prefix) {
    entry.name.replace(old=prefix, new="")
  } else {
    entry.name
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
