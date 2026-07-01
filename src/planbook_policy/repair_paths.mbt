///|
pub fn repair_context_relative_path() -> String {
  "raw/repair/PLANBOOK_REPAIR_CONTEXT.md"
}

///|
pub fn repair_result_relative_path() -> String {
  "raw/repair/repair-result.md"
}

///|
pub fn repair_superseded_result_relative_path() -> String {
  "raw/repair/repair-result.superseded.md"
}

///|
pub fn repair_skill_relative_path() -> String {
  "skills/planbook-repair/SKILL.md"
}

///|
pub fn repair_plan_relative_path() -> String {
  "plans/self-healing-repair/plan.md"
}

///|
pub fn repair_raw_dir(workspace_root : String) -> String {
  "\{workspace_root}/raw/repair"
}

///|
pub fn repair_task_id(criterion_id : String) -> String {
  "planbook-repair-\{criterion_id}"
}

///|
pub fn repair_result_target_pages() -> Array[String] {
  [
    repair_result_relative_path(),
    "wiki/reviews/active-plan-review.md",
    "wiki/planning/execution-evidence.md",
  ]
}

///|
pub fn repair_context_pages() -> Array[String] {
  [
    repair_context_relative_path(),
    repair_plan_relative_path(),
    "wiki/planning/self-healing.md",
    "wiki/reviews/active-plan-review.md",
  ]
}

///|
pub fn repair_skill_paths() -> Array[String] {
  [repair_skill_relative_path()]
}

///|
pub fn repair_path_in_workspace(
  workspace_root : String,
  relative_path : String,
) -> String {
  "\{workspace_root}/\{relative_path}"
}

///|
pub fn repair_result_path_for_workspace(workspace_root : String) -> String {
  repair_path_in_workspace(workspace_root, repair_result_relative_path())
}

///|
pub fn repair_result_path(task : PlanbookRepairTask) -> String {
  repair_result_path_for_workspace(task.workspace_root)
}

///|
pub fn repair_superseded_result_path(workspace_root : String) -> String {
  repair_path_in_workspace(
    workspace_root,
    repair_superseded_result_relative_path(),
  )
}

///|
pub fn repair_packet_path(workspace_root : String, task_id : String) -> String {
  "\{repair_raw_dir(workspace_root)}/\{task_id}.packet.json"
}

///|
pub fn repair_packet_path_for_criterion(
  workspace_root : String,
  criterion_id : String,
) -> String {
  repair_packet_path(workspace_root, repair_task_id(criterion_id))
}

///|
pub fn repair_context_path(workspace_root : String) -> String {
  repair_path_in_workspace(workspace_root, repair_context_relative_path())
}

///|
pub fn repair_skill_path(workspace_root : String) -> String {
  repair_path_in_workspace(workspace_root, repair_skill_relative_path())
}

///|
pub fn repair_plan_path(workspace_root : String) -> String {
  repair_path_in_workspace(workspace_root, repair_plan_relative_path())
}

///|
pub fn repair_job_index_path(workspace_root : String) -> String {
  @moonsuite.product_artifact_for_book_root(
    workspace_root, "moonclaw", "jobs/index/runs.json",
  )
}

///|
pub fn repair_job_proposals_path(workspace_root : String) -> String {
  @moonsuite.product_artifact_for_book_root(
    workspace_root, "moonclaw", "jobs/job_proposals.json",
  )
}

///|
pub fn repair_workspace_status_page_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/self-healing-repair.md"
}
