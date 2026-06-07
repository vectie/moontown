///|
fn planbook_repair_result_contract() -> String {
  "planbook.repair.result.v1"
}

///|
fn planbook_repair_context_relative_path() -> String {
  "raw/repair/PLANBOOK_REPAIR_CONTEXT.md"
}

///|
fn planbook_repair_result_relative_path() -> String {
  "raw/repair/repair-result.md"
}

///|
fn planbook_repair_superseded_result_relative_path() -> String {
  "raw/repair/repair-result.superseded.md"
}

///|
fn planbook_repair_skill_relative_path() -> String {
  "skills/planbook-repair/SKILL.md"
}

///|
fn planbook_repair_plan_relative_path() -> String {
  "plans/self-healing-repair/plan.md"
}

///|
fn planbook_repair_raw_dir(workspace_root : String) -> String {
  "\{workspace_root}/raw/repair"
}

///|
fn planbook_repair_task_id(criterion_id : String) -> String {
  "planbook-repair-\{criterion_id}"
}

///|
fn planbook_repair_result_target_pages() -> Array[String] {
  [
    planbook_repair_result_relative_path(),
    "wiki/reviews/active-plan-review.md",
    "wiki/planning/execution-evidence.md",
  ]
}

///|
fn planbook_repair_context_pages() -> Array[String] {
  [
    planbook_repair_context_relative_path(),
    planbook_repair_plan_relative_path(),
    "wiki/planning/self-healing.md",
    "wiki/reviews/active-plan-review.md",
  ]
}

///|
fn planbook_repair_skill_paths() -> Array[String] {
  [planbook_repair_skill_relative_path()]
}

///|
fn planbook_repair_path_in_workspace(
  workspace_root : String,
  relative_path : String,
) -> String {
  "\{workspace_root}/\{relative_path}"
}

///|
fn planbook_repair_result_path_for_workspace(workspace_root : String) -> String {
  "\{planbook_repair_raw_dir(workspace_root)}/repair-result.md"
}

///|
fn planbook_repair_result_path(task : PlanbookRepairTask) -> String {
  planbook_repair_result_path_for_workspace(task.workspace_root)
}

///|
fn planbook_repair_superseded_result_path(workspace_root : String) -> String {
  planbook_repair_path_in_workspace(
    workspace_root,
    planbook_repair_superseded_result_relative_path(),
  )
}

///|
fn planbook_repair_packet_path(
  workspace_root : String,
  task_id : String,
) -> String {
  "\{planbook_repair_raw_dir(workspace_root)}/\{task_id}.packet.json"
}

///|
fn planbook_repair_packet_path_for_criterion(
  workspace_root : String,
  criterion_id : String,
) -> String {
  planbook_repair_packet_path(
    workspace_root,
    planbook_repair_task_id(criterion_id),
  )
}

///|
fn planbook_repair_context_path(workspace_root : String) -> String {
  planbook_repair_path_in_workspace(
    workspace_root,
    planbook_repair_context_relative_path(),
  )
}

///|
fn planbook_repair_skill_path(workspace_root : String) -> String {
  planbook_repair_path_in_workspace(
    workspace_root,
    planbook_repair_skill_relative_path(),
  )
}

///|
fn planbook_repair_plan_path(workspace_root : String) -> String {
  planbook_repair_path_in_workspace(
    workspace_root,
    planbook_repair_plan_relative_path(),
  )
}

///|
fn planbook_repair_job_index_path(workspace_root : String) -> String {
  "\{workspace_root}/.moonclaw/jobs/index/runs.json"
}

///|
fn planbook_repair_job_proposals_path(workspace_root : String) -> String {
  "\{workspace_root}/.moonclaw/jobs/job_proposals.json"
}

///|
fn planbook_repair_workspace_status_page_path(
  workspace_root : String,
) -> String {
  "\{workspace_root}/wiki/planning/self-healing-repair.md"
}
