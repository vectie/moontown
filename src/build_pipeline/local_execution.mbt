///|
pub fn local_wenyu_build_execution_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
) -> @core.TaskExecutionRecord {
  let packet_id = "local-\{entry.id}-\{task.id}"
  let status : @core.TaskExecutionStatus = if task.kind == "code-patch" {
    ReviewQueued
  } else {
    Completed
  }
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id~,
    packet_path="local://wenyu-build/\{entry.id}/\{task.id}",
    proposal_id=Some("local-wenyu-build-materializer"),
    run_id=None,
    status~,
    summary="MoonTown used the local Wenyu build materializer for `\{task.kind}` because the current MoonClaw/Codex ACP path can start build controllers but does not provide reliable writable repository execution yet.",
    output_contract=wenyu_build_packet_contract(),
    context_pages=task.target_pages,
    skill_paths=[
      "skills/wenyu-build/SKILL.md", "skills/wenyu-code-patch/SKILL.md", "skills/wenyu-asset-pack/SKILL.md",
    ],
    assigned_worker_id~,
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + local_wenyu_execution_stale_window_ticks(),
    next_retry_tick=None,
    requires_review=task.requires_review || task.kind == "code-patch",
    notify_town=true,
  )
}

///|
pub fn local_wenyu_execution_stale_window_ticks() -> Int {
  3
}
