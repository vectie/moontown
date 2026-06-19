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
    run_inline=moontown_moonclaw_inline_enabled(),
  )
  let execution_command = match imported.run_id {
    Some(run_id) => {
      let initial = @moonclaw.poll_run(
        task.id,
        run_id,
        cwd=entry.workspace_root,
        detect_orphan=false,
      )
      if initial.status is RunConfirmed {
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
  assigned_worker_id? : String? = None,
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
    status=Failed,
    summary=detail,
    output_contract="keeper.plan.packet.v1",
    assigned_worker_id~,
    requires_review=task.requires_review,
    notify_town=true,
  )
}
