///|
fn planbook_repair_packet_metadata(criterion : PlanbookCriterionStatus) -> Json {
  let fields : Map[String, Json] = {}
  fields["producer"] = "moontown".to_json()
  fields["book_id"] = default_planbook_book_id().to_json()
  fields["criterion_id"] = criterion.id.to_json()
  fields["plan_id"] = criterion.plan_id.to_json()
  fields["owner"] = criterion.owner.to_json()
  add_planbook_repair_wait_policy(fields)
  fields["profile_metadata"] = planbook_repair_wait_policy_json()
  fields["step_metadata"] = planbook_repair_packet_step_metadata(criterion)
  Json::object(fields)
}

///|
fn planbook_repair_packet_step_metadata(
  criterion : PlanbookCriterionStatus,
) -> Json {
  let fields = moonclaw_execution_metadata_fields(
    preferred_skills=planbook_repair_preferred_skills(),
    execution_mode="acp",
    execution_target=Some("codex-main"),
    output_contract=planbook_repair_result_contract(),
  )
  fields["kind"] = "planbook_repair".to_json()
  fields["source_root"] = planbook_repair_source_root().to_json()
  fields["target_files"] = planbook_repair_target_files(criterion.id).to_json()
  fields["required_validation_commands"] = planbook_repair_required_commands().to_json()
  fields["required_engineering_steps"] = planbook_repair_required_engineering_steps().to_json()
  fields["git_policy"] = planbook_repair_git_policy_json()
  fields["target_pages"] = planbook_repair_result_target_pages().to_json()
  add_planbook_repair_wait_policy(fields)
  Json::object(fields)
}

///|
fn add_planbook_repair_wait_policy(fields : Map[String, Json]) -> Unit {
  add_planbook_bounded_wait_policy(fields)
}

///|
fn planbook_repair_wait_policy_json() -> Json {
  planbook_bounded_wait_policy_json()
}

///|
fn planbook_repair_preferred_skills() -> Array[String] {
  ["planbook-repair", "code-plan", "code-review"]
}

///|
fn planbook_repair_required_engineering_steps() -> Array[String] {
  [
    "inspect-plan", "apply-small-patch", "run-validation", "inspect-git-diff", "write-repair-result",
    "prepare-commit-summary",
  ]
}

///|
fn planbook_repair_git_policy_json() -> Json {
  {
    "inspect_status": true,
    "inspect_diff": true,
    "commit_after_validation": true,
    "push_after_commit": false,
    "commit_message_required": true,
  }
}
