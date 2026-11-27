///|
fn planbook_bounded_step_metadata_json(
  preferred_skills~ : Array[String],
  execution_mode~ : String,
  execution_target~ : String? = None,
  output_contract~ : String,
  source_root~ : String,
  target_files~ : Array[String],
  target_pages~ : Array[String],
  planning_layer~ : String,
  runtime_mode~ : String,
  tool_access~ : String,
) -> Json {
  let fields = moonclaw_execution_metadata_fields(
    preferred_skills~,
    execution_mode~,
    execution_target~,
    output_contract~,
  )
  fields["enable_tools"] = ToJson::to_json(true)
  fields["source_root"] = ToJson::to_json(source_root)
  fields["target_files"] = ToJson::to_json(target_files)
  fields["target_pages"] = ToJson::to_json(target_pages)
  fields["best_effort_on_timeout"] = ToJson::to_json(false)
  fields["timeout_ms"] = ToJson::to_json(600000)
  fields["role_runtime"] = planbook_bounded_role_runtime_json(
    planning_layer~,
    runtime_mode~,
    tool_access~,
    output_contract~,
  )
  Json::object(fields)
}

///|
fn planbook_bounded_role_runtime_json(
  planning_layer~ : String,
  runtime_mode~ : String,
  tool_access~ : String,
  output_contract~ : String,
) -> Json {
  {
    "planning_layer": planning_layer,
    "runtime_mode": runtime_mode,
    "tool_access": tool_access,
    "memory_scope": "planbook",
    "allow_delegate": false,
    "allow_workspace_write": true,
    "allow_execution_tools": true,
    "output_contract": output_contract,
  }
}
