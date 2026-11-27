///|
fn planbook_repair_packet_metadata(criterion : PlanbookCriterionStatus) -> Json {
  let fields : Map[String, Json] = Map([])
  fields["producer"] = ToJson::to_json("moontown")
  fields["book_id"] = ToJson::to_json(default_planbook_book_id())
  fields["criterion_id"] = ToJson::to_json(criterion.id)
  fields["plan_id"] = ToJson::to_json(criterion.plan_id)
  fields["owner"] = ToJson::to_json(criterion.owner)
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
    execution_target=Some(@codex.codex_main_target_id()),
    output_contract=planbook_repair_result_contract(),
  )
  fields["kind"] = ToJson::to_json("planbook_repair")
  fields["criterion_id"] = ToJson::to_json(criterion.id)
  fields["source_root"] = ToJson::to_json(planbook_repair_source_root())
  fields["target_files"] = ToJson::to_json(
    planbook_repair_target_files(criterion.id),
  )
  fields["required_validation_commands"] = ToJson::to_json(
    planbook_repair_required_commands(),
  )
  fields["required_engineering_steps"] = ToJson::to_json(
    @planbook_policy.repair_required_engineering_steps(),
  )
  fields["patch_receipt_contract"] = ToJson::to_json(
    @planbook_policy.repair_patch_receipt_contract(),
  )
  fields["patch_receipt_required_fields"] = ToJson::to_json(
    @planbook_policy.repair_patch_receipt_required_fields(),
  )
  fields["git_policy"] = @planbook_policy.repair_git_policy_json()
  fields["target_pages"] = ToJson::to_json(
    planbook_repair_result_target_pages(),
  )
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
