///|
async fn write_civic_salon_reducer_workspace(
  scenario : CivicSalonScenario,
  root : String,
  round_id : String,
  round_number : Int,
) -> Unit {
  @support.write_text_file(
    "\{root}/skills/\{scenario.skill_name}/SKILL.md",
    @civic.salon_reducer_skill_text(scenario),
  )
  @support.write_text_file(
    "\{root}/\{@civic.civic_reducer_participants_relative_path()}",
    scenario.participants.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    "\{root}/\{@civic.civic_reducer_input_relative_path()}",
    @civic.salon_reducer_input_markdown(scenario, round_id, round_number),
  )
  @support.write_text_file(
    "\{root}/\{@civic.civic_reducer_contract_relative_path()}",
    @civic.salon_reducer_contract_markdown(scenario),
  )
  @support.write_text_file(
    "\{root}/moonclaw.jobs.json",
    merged_civic_salon_reducer_profile_json(root, scenario),
  )
}

///|
async fn merged_civic_salon_reducer_profile_json(
  root : String,
  scenario : CivicSalonScenario,
) -> String {
  let path = "\{root}/moonclaw.jobs.json"
  let existing = @support.read_json_file_or_empty_object(path)
  let reducer_profile = civic_salon_reducer_profile_json(scenario)
  @support.upsert_moonclaw_job_profile_json(
    existing,
    @civic.civic_reducer_profile_family(),
    reducer_profile,
  ).stringify(indent=2)
}

///|
fn civic_salon_reducer_profile_json(scenario : CivicSalonScenario) -> Json {
  let pattern = @civic.communication_pattern_for_scenario(scenario)
  {
    "family": @civic.civic_reducer_profile_family(),
    "role": "worker",
    "priority": 155,
    "tags": [
      "civic",
      "communication-pattern",
      pattern.id,
      "reducer",
      scenario.building_id,
    ],
    "match": {
      "all": ["civic-communication-pattern", "reducer"],
      "any": [pattern.id, scenario.id, scenario.building_id],
    },
    "steps": [
      {
        "id": "reduce_civic_pattern_outputs",
        "title": "Reduce communication-pattern participant packets into reviewable outputs",
        "kind": "job.analysis",
        "prompt_template": civic_salon_reducer_prompt_template(),
        "metadata": civic_salon_reducer_step_metadata(scenario, pattern),
      },
    ],
  }
}

///|
fn civic_salon_reducer_prompt_template() -> String {
  "Read ${proposal.request_text}. Then read the listed context pages and skill_paths. Write \{@civic.civic_reducer_output_relative_path()} only after validating the \{@civic.civic_reducer_output_contract_type_name()} contract. Do not wait for input and do not use template seed ideas."
}

///|
fn civic_salon_reducer_step_metadata(
  scenario : CivicSalonScenario,
  pattern : @civic.CivicCommunicationPattern,
) -> Json {
  let fields = @moonclaw_runtime.moonclaw_step_metadata_fields(
    preferred_skills=[scenario.skill_name],
    enable_tools=true,
    web_search=false,
    timeout_ms=600000,
    board_lane=pattern.title,
    board_order=0,
  )
  fields["communication_pattern_id"] = pattern.id.to_json()
  fields["role_runtime"] = civic_salon_reducer_role_runtime(pattern)
  Json::object(fields)
}

///|
fn civic_salon_reducer_role_runtime(
  pattern : @civic.CivicCommunicationPattern,
) -> Json {
  {
    "planning_layer": "domain",
    "runtime_mode": "reducer",
    "tool_access": "workspace",
    "memory_scope": "domain",
    "allow_delegate": false,
    "allow_workspace_write": true,
    "allow_execution_tools": true,
    "output_contract": pattern.output_contract,
  }
}
