///|
fn planbook_repair_result_contract() -> String {
  @planbook_policy.repair_result_contract()
}

///|
fn planbook_repair_result_relative_path() -> String {
  @planbook_policy.repair_result_relative_path()
}

///|
fn planbook_repair_task_id(criterion_id : String) -> String {
  @planbook_policy.repair_task_id(criterion_id)
}

///|
fn planbook_repair_result_target_pages() -> Array[String] {
  @planbook_policy.repair_result_target_pages()
}

///|
fn planbook_repair_context_pages() -> Array[String] {
  @planbook_policy.repair_context_pages()
}

///|
fn planbook_repair_skill_paths() -> Array[String] {
  @planbook_policy.repair_skill_paths()
}

///|
fn planbook_repair_result_path_for_workspace(workspace_root : String) -> String {
  @planbook_policy.repair_result_path_for_workspace(workspace_root)
}

///|
fn planbook_repair_result_path(task : PlanbookRepairTask) -> String {
  @planbook_policy.repair_result_path(task)
}

///|
fn planbook_repair_superseded_result_path(workspace_root : String) -> String {
  @planbook_policy.repair_superseded_result_path(workspace_root)
}

///|
fn planbook_repair_packet_path(
  workspace_root : String,
  task_id : String,
) -> String {
  @planbook_policy.repair_packet_path(workspace_root, task_id)
}

///|
fn planbook_repair_packet_path_for_criterion(
  workspace_root : String,
  criterion_id : String,
) -> String {
  @planbook_policy.repair_packet_path_for_criterion(
    workspace_root, criterion_id,
  )
}

///|
fn planbook_repair_context_path(workspace_root : String) -> String {
  @planbook_policy.repair_context_path(workspace_root)
}

///|
fn planbook_repair_skill_path(workspace_root : String) -> String {
  @planbook_policy.repair_skill_path(workspace_root)
}

///|
fn planbook_repair_plan_path(workspace_root : String) -> String {
  @planbook_policy.repair_plan_path(workspace_root)
}

///|
fn planbook_repair_job_index_path(workspace_root : String) -> String {
  @planbook_policy.repair_job_index_path(workspace_root)
}

///|
fn planbook_repair_job_proposals_path(workspace_root : String) -> String {
  @planbook_policy.repair_job_proposals_path(workspace_root)
}

///|
fn planbook_repair_workspace_status_page_path(
  workspace_root : String,
) -> String {
  @planbook_policy.repair_workspace_status_page_path(workspace_root)
}
