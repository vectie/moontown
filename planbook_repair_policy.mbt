///|
fn first_planbook_open_criterion(
  status : PlanbookAutonomyStatus,
) -> PlanbookCriterionStatus? {
  for item in status.criteria {
    if !item.satisfied {
      return Some(item)
    }
  }
  None
}

///|
fn planbook_noop_repair_task(
  snapshot_path : String,
  workspace_root : String,
) -> PlanbookRepairTask {
  ignore(snapshot_path)
  {
    id: "planbook-repair-none",
    criterion_id: "none",
    title: "No open PlanBook gap",
    status: "idle",
    owner: "moontown",
    workspace_root,
    packet_path: "",
    proposal_id: None,
    run_id: None,
    summary: "No open PlanBook gap was found.",
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: @env.now(),
  }
}

///|
fn planbook_repair_validation_command() -> String {
  @planbook_policy.repair_validation_command()
}

///|
fn planbook_repair_required_commands() -> Array[String] {
  @planbook_policy.repair_required_commands()
}
