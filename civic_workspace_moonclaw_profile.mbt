///|
async fn ensure_wenyu_civic_moonclaw_profile(root : String) -> Unit {
  let path = "\{root}/moonclaw.jobs.json"
  let existing = read_json_file_or_empty_object(path)
  let profile = wenyu_civic_moonclaw_profile_json()
  write_text_file(
    path,
    upsert_moonclaw_job_profile_json(
      existing, "wenyu_civic_service_worker", profile,
    ).stringify(indent=2),
  )
}

///|
fn wenyu_civic_moonclaw_profile_json() -> Json {
  {
    "family": "wenyu_civic_service_worker",
    "role": "worker",
    "priority": 145,
    "tags": ["wenyu", "civic", "service", "review", "projection"],
    "match": {
      "all": ["civic"],
      "any": [
        "service", "policy", "contest", "social", "talent", "market", "bridge", "story",
        "education",
      ],
    },
    "steps": [wenyu_civic_execute_step_json(), wenyu_civic_review_step_json()],
    "metadata": { "role_runtime": wenyu_civic_service_role_runtime_json() },
  }
}

///|
fn wenyu_civic_execute_step_json() -> Json {
  {
    "id": "execute_civic_service",
    "title": "Execute Wenyu civic service packet",
    "kind": "job.analysis",
    "prompt_template": wenyu_civic_execute_prompt_template(),
    "metadata": wenyu_civic_execute_step_metadata_json(),
  }
}

///|
fn wenyu_civic_review_step_json() -> Json {
  {
    "id": "review_civic_service",
    "title": "Review Wenyu civic service output",
    "kind": "job.analysis",
    "prompt_template": wenyu_civic_review_prompt_template(),
    "metadata": wenyu_civic_review_step_metadata_json(),
  }
}

///|
fn wenyu_civic_execute_step_metadata_json() -> Json {
  let fields = moonclaw_step_metadata_fields(
    preferred_skills=wenyu_civic_preferred_skills(),
    enable_tools=true,
    web_search=true,
    timeout_ms=600000,
    board_lane="Civic Service",
    board_order=0,
  )
  fields["role_runtime"] = wenyu_civic_service_role_runtime_json()
  Json::object(fields)
}

///|
fn wenyu_civic_review_step_metadata_json() -> Json {
  Json::object(
    moonclaw_step_metadata_fields(
      preferred_skills=wenyu_civic_preferred_skills(),
      enable_tools=true,
      web_search=false,
      timeout_ms=300000,
      board_lane="Review",
      board_order=1,
    ),
  )
}

///|
fn wenyu_civic_preferred_skills() -> Array[String] {
  ["wenyu-civic-service"]
}

///|
fn wenyu_civic_service_role_runtime_json() -> Json {
  {
    "planning_layer": "domain",
    "runtime_mode": "service",
    "tool_access": "workspace",
    "memory_scope": "domain",
    "allow_delegate": false,
    "allow_workspace_write": true,
    "allow_execution_tools": true,
    "output_contract": "wenyu.civic.service_packet.v1",
  }
}

///|
fn wenyu_civic_execute_prompt_template() -> String {
  [
    "Execute the imported Wenyu civic service packet for ${proposal.title}.",
    "Read \{wenyu_civic_execute_context_requirements().join(", ")}.",
    "This is a module-native building protocol operation, not a generic report or generic research lane.",
    wenyu_civic_execute_protocol_rule_text(),
    wenyu_civic_execute_action_rule_text(),
    "Return Markdown with \{wenyu_civic_service_result_fields().join(", ")}.",
    "Do not wait for input; if a required source or authority is missing, write a blocker and a review item.",
  ].join(" ")
}

///|
fn wenyu_civic_review_prompt_template() -> String {
  [
    "Review the civic service output for ${proposal.title}.", "Confirm that changed pages, basis for the protocol decision, review items, projection delta, and next_check_hint are present.",
    "Reject outputs that use disallowed channels, count operational retries as domain progress, claim external completion without approval, or expose private memory.",
    "Return concise Markdown with pass/fail, blockers, and required in-place repairs.",
  ].join(" ")
}

///|
fn wenyu_civic_execute_context_requirements() -> Array[String] {
  [
    "`raw/bootstrap/CIVIC_SERVICE_CONTRACT.md`", "`raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`",
    "`skills/wenyu-civic-service/SKILL.md`", "the module-specific `SKILL.md` listed in `skill_paths`",
    "the existing wiki/review pages",
  ]
}

///|
fn wenyu_civic_execute_protocol_rule_text() -> String {
  "Follow the module mode, MoonBook role, skill mode, input channels, output channels, review gates, and distribution policy from the contracts."
}

///|
fn wenyu_civic_execute_action_rule_text() -> String {
  [
    "Map inputs into contributions, group useful compatible contributions, reduce them into a building-native output, and distribute only through allowed channels.",
    "Use web/source research only when the dedicated skill requires it; otherwise produce the appropriate exchange, projection, ledger, gateway, coaching, tutorial, story, or review artifact.",
    "Let the model choose the best next action from current book and place state, but obey review gates.",
    "Write or update only permitted artifacts unless the packet explicitly permits external output.",
  ].join(" ")
}

///|
fn wenyu_civic_service_result_fields() -> Array[String] {
  [
    "civic_service_decision", "book_changed", "wiki_pages_changed_count", "accepted_facts_count",
    "changed_pages", "review_items_created_count", "review_items", "projection_updated",
    "projection_delta", "protocol_decision_basis", "next_check_hint", "artifacts",
    "blockers", "review items",
  ]
}
