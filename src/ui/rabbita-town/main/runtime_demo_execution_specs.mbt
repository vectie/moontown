///|
fn execution_specs(model : Model) -> Array[@core.TaskExecutionRecord] {
  [
    execution_spec(
      model, "task-town-shell-implementation-backlog", "wenyu-town-shell", 0,
    ),
    execution_spec(model, "task-town-shell-code-patch", "wenyu-town-shell", 1),
    execution_spec(
      model, "task-town-shell-image-asset-pack", "wenyu-town-shell", 2,
    ),
    execution_spec(
      model, "task-resident-twins-code-patch", "wenyu-resident-twins", 3,
    ),
    execution_spec(model, "task-policy-quest", "policy-hall", 4),
    execution_spec(model, "task-contest-readiness", "wenyu-contest-express", 5),
    execution_spec(model, "task-cafe-match", "social-square", 6),
    execution_spec(model, "task-talent-graph", "talent-avenue", 7),
    execution_spec(model, "task-ai-tip", "ai-garden", 8),
    execution_spec(
      model, "task-physical-bridge-sync", "wenyu-physical-bridge", 9,
    ),
  ]
}

///|
fn execution_spec(
  model : Model,
  task_id : String,
  book_id : String,
  offset : Int,
) -> @core.TaskExecutionRecord {
  let status = execution_status_for(model, offset)
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id="packet-\{task_id}",
    packet_path=".moonsuite/products/moontown/packets/packet-\{task_id}.json",
    proposal_id=Some("proposal-packet-\{task_id}"),
    run_id=if execution_status_has_run_id(status) {
      Some("run-packet-\{task_id}")
    } else {
      None
    },
    status~,
    summary=execution_summary(status, task_id),
    output_contract="keeper.plan.packet.v1",
    context_pages=["wiki/index.md", "wiki/log.md"],
    skill_paths=["skills/wiki-maintainer/SKILL.md"],
    requires_review=execution_status_requires_review(status),
    notify_town=true,
  )
}

///|
fn execution_status_for(
  model : Model,
  offset : Int,
) -> @core.TaskExecutionStatus {
  if mayor_recovery_active(model) && offset == 4 {
    RunConfirmed
  } else if model.stability < 26 && offset == 3 {
    ReviewQueued
  } else {
    match (model.tick + offset) % 7 {
      0 => PacketReady
      1 => ProposalImported
      2 => RunConfirmed
      3 => Running
      4 => AwaitingPersistence
      5 => ReviewQueued
      _ => Completed
    }
  }
}

///|
fn execution_summary(
  status : @core.TaskExecutionStatus,
  task_id : String,
) -> String {
  match status {
    PacketReady =>
      "Keeper packet prepared for \{task_id}."
    ProposalImported =>
      "Proposal imported and waiting for mayor confirmation."
    RunConfirmed =>
      "Mayor confirmed a live MoonClaw run."
    Running =>
      "MoonClaw run is executing book-local work."
    AwaitingPersistence =>
      "MoonBook persistence is waiting to absorb the result."
    ReviewQueued =>
      "Keeper review queued after persistence."
    Completed =>
      "Packet, run, and review loop completed."
    Stale =>
      "Mayor marked the execution stale and queued a recovery decision."
    Failed =>
      "Execution failed and the town should recover or retry."
  }
}
