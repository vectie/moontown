///|
async fn existing_planbook_repair_in_flight(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
  workspace_root : String,
) -> PlanbookRepairTask? {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return latest_planbook_repair_task_from_job_index(criterion, workspace_root)
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ =>
      return latest_planbook_repair_task_from_job_index(
        criterion, workspace_root,
      )
  }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ =>
      return latest_planbook_repair_task_from_job_index(
        criterion, workspace_root,
      )
  }
  if task.criterion_id != criterion.id {
    match
      latest_planbook_repair_task_from_job_index(criterion, workspace_root) {
      Some(index_task) if planbook_repair_task_in_flight(index_task) =>
        return Some(index_task)
      _ => return None
    }
  }
  if planbook_repair_task_in_flight(task) {
    Some(task)
  } else {
    match
      latest_planbook_repair_task_from_job_index(criterion, workspace_root) {
      Some(index_task) if planbook_repair_task_in_flight(index_task) =>
        Some(index_task)
      _ => None
    }
  }
}

///|
async fn existing_planbook_repair_handoff(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
  workspace_root : String,
) -> PlanbookRepairTask? {
  ignore(snapshot_path)
  let result_path = planbook_repair_result_path_for_workspace(workspace_root)
  let result_text = read_text_or_empty(result_path)
  if !planbook_repair_result_mentions_criterion(result_text, criterion.id) {
    return None
  }
  if !planbook_repair_result_has_handoff_decision(result_text) {
    return None
  }
  if planbook_repair_handoff_is_stale(criterion, result_text) {
    return None
  }
  Some({
    id: planbook_repair_task_id(criterion.id),
    criterion_id: criterion.id,
    title: criterion.title,
    status: "blocked",
    owner: criterion.owner,
    workspace_root,
    packet_path: planbook_repair_packet_path_for_criterion(
      workspace_root,
      criterion.id,
    ),
    proposal_id: None,
    run_id: None,
    summary: "Existing repair result classifies this gap as an ownership handoff. Moontown will not dispatch duplicate repair packets until the owner boundary changes or the result is cleared.",
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: @env.now(),
  })
}

///|
fn planbook_repair_handoff_is_stale(
  criterion : PlanbookCriterionStatus,
  result_text : String,
) -> Bool {
  match criterion.id {
    "live-runtime-recovery" => !result_text.contains(criterion.evidence)
    _ => false
  }
}

///|
async fn planbook_repair_criterion_now_satisfied(
  task : PlanbookRepairTask,
) -> Bool {
  match task.criterion_id {
    "moonbook-native-planbook-provider" =>
      @fs.exists("../moonbook/seed/wiki/skills/code-plan/SKILL.md") ||
      @fs.exists("../moonbook/seed/wiki/skills/planbook/SKILL.md")
    "live-runtime-recovery" => {
      let status = inspect_moontown_planbook_autonomy()
      for item in status.criteria {
        if item.id == "live-runtime-recovery" {
          return item.satisfied
        }
      }
      false
    }
    _ => false
  }
}
