///|
async fn write_planbook_repair_moonclaw_profile(
  workspace_root : String,
) -> Unit {
  let path = "\{workspace_root}/moonclaw.jobs.json"
  let base = @support.read_json_file_or_empty_object(path)
  @support.write_text_file(
    path,
    @support.upsert_moonclaw_job_profile_json(
      base,
      planbook_repair_worker_profile_id(),
      planbook_repair_worker_profile_json(),
    ).stringify(indent=2),
  )
}

///|
fn planbook_repair_worker_profile_json() -> Json {
  {
    "family": planbook_repair_worker_profile_id(),
    "role": "worker",
    "priority": 180,
    "tags": ["planbook", "self-healing", "repair"],
    "match": planbook_repair_worker_match_json(),
    "steps": [planbook_repair_worker_step_json()],
    "metadata": {
      "owner": "moontown-planbook",
      "purpose": planbook_repair_worker_profile_purpose(),
    },
  }
}

///|
fn planbook_repair_worker_profile_id() -> String {
  @moonclaw_policy.planbook_keeper_profile()
}

///|
fn planbook_repair_worker_profile_purpose() -> String {
  "Repair one PlanBook self-build criterion without leaking MoonBook or MoonClaw ownership into Moontown."
}

///|
fn planbook_repair_worker_match_json() -> Json {
  { "all": ["planbook", "repair"], "any": ["self-healing", "gap", "criterion"] }
}

///|
fn planbook_repair_worker_step_json() -> Json {
  {
    "id": "repair_planbook_gap",
    "title": "Repair one bounded PlanBook self-build gap",
    "kind": "job.analysis",
    "prompt_template": planbook_repair_worker_prompt_template(),
    "metadata": planbook_repair_worker_step_metadata_json(),
  }
}

///|
fn planbook_repair_worker_step_metadata_json() -> Json {
  planbook_bounded_step_metadata_json(
    preferred_skills=planbook_repair_preferred_skills(),
    execution_mode="acp",
    execution_target=Some(@codex.codex_main_target_id()),
    output_contract=planbook_repair_result_contract(),
    source_root=planbook_repair_source_root(),
    target_files=planbook_repair_target_files("default"),
    target_pages=planbook_repair_result_target_pages(),
    planning_layer="town-self-healing",
    runtime_mode="bounded-repair",
    tool_access="codex-acp-repo-patch",
  )
}

///|
fn planbook_repair_worker_prompt_template() -> String {
  [
    "Read ${proposal.request_text}.",
    "Then read context_pages and skill_paths.",
    "Use the exact target_files before any broader search.",
    "Make the smallest safe repair or return a precise ownership blocker.",
    "Write \{planbook_repair_result_relative_path()} with the \{planbook_repair_result_contract()} contract.",
  ].join(" ")
}
