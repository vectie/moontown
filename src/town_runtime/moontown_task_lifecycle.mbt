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
fn modeled_lifecycle_execution_record(
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
    summary="Modeled bootstrap lifecycle for \{task.id}",
    output_contract="keeper.plan.packet.v1",
    context_pages=["wiki/index.md", "wiki/log.md"],
    skill_paths=["skills/wiki-maintainer/SKILL.md"],
    requires_review=status == @core.TaskExecutionStatus::ReviewQueued,
    notify_town=true,
  )
}
