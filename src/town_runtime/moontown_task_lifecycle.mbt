///|
fn execution_status_for_index(index : Int) -> @core.TaskExecutionStatus {
  match index {
    0 => ProposalImported
    1 => Running
    2 => AwaitingPersistence
    3 => ReviewQueued
    _ => PacketReady
  }
}

///|
fn modeled_lifecycle_execution_record(
  task : @core.TownTask,
  index : Int,
) -> @core.TaskExecutionRecord {
  let status = execution_status_for_index(index)
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=task.book_id,
    packet_id="packet-\{task.id}",
    packet_path=@moonclaw.packet_file_path(
      @moonclaw.default_packet_directory(),
      "packet-\{task.id}",
    ),
    proposal_id=Some("proposal-packet-\{task.id}"),
    run_id=if status == ProposalImported {
      None
    } else {
      Some("run-packet-\{task.id}")
    },
    status~,
    summary="Modeled bootstrap lifecycle for \{task.id}",
    output_contract="keeper.plan.packet.v1",
    context_pages=["wiki/index.md", "wiki/log.md"],
    skill_paths=["skills/wiki-maintainer/SKILL.md"],
    requires_review=status == ReviewQueued,
    notify_town=true,
  )
}
