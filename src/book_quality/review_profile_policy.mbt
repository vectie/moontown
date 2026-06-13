///|
pub fn review_profile_id() -> String {
  "book_quality_ai_reviewer"
}

///|
pub fn review_execution_target() -> String {
  @codex.codex_main_target_id()
}

///|
pub fn review_preferred_skills() -> Array[String] {
  ["book-quality-ai-review"]
}

///|
pub fn review_role_runtime_json() -> Json {
  {
    "planning_layer": "town-quality-governance",
    "runtime_mode": "semantic-review",
    "tool_access": "workspace-read",
    "memory_scope": "book-quality",
    "allow_delegate": false,
    "allow_workspace_write": false,
    "allow_execution_tools": true,
    "output_contract": review_output_contract(),
  }
}

///|
pub fn review_moonclaw_jobs_json() -> Json {
  let profiles : Map[String, Json] = {}
  profiles[review_profile_id()] = review_profile_json()
  { "jobs": { "profiles": Json::object(profiles) } }
}

///|
pub fn review_acp_config_json(
  source_root : String,
  command : String,
  args : Array[String],
  model : String,
) -> Json {
  let targets : Map[String, Json] = {}
  targets[review_execution_target()] = @codex.codex_acp_target_json(
    source_root, "Codex Book Quality Reviewer", command, args, model,
  )
  { "acp": { "targets": Json::object(targets) } }
}

///|
fn review_packet_step_metadata_json(output_contract : String) -> Json {
  let metadata = review_execution_metadata_fields(output_contract)
  metadata["kind"] = "book_quality_ai_review".to_json()
  Json::object(metadata)
}

///|
fn review_profile_json() -> Json {
  {
    "family": review_profile_id(),
    "role": "reviewer",
    "priority": 170,
    "tags": ["book-quality", "ai-review", "semantic-review"],
    "match": {
      "all": ["book-quality", "ai-review"],
      "any": @policy.reviewable_types(),
    },
    "steps": [review_step_json()],
  }
}

///|
fn review_step_json() -> Json {
  {
    "id": "review_book_semantic_quality",
    "title": "Review one MoonBook workspace for real semantic quality",
    "kind": "job.analysis",
    "prompt_template": "Read ${proposal.request_text}. Read all absolute context_pages and skill_paths. Return exactly the requested book quality AI review contract. Do not write files.",
    "metadata": review_profile_step_metadata_json(),
  }
}

///|
fn review_profile_step_metadata_json() -> Json {
  let metadata = review_execution_metadata_fields(review_output_contract())
  metadata["enable_tools"] = true.to_json()
  metadata["role_runtime"] = review_role_runtime_json()
  Json::object(metadata)
}

///|
fn review_execution_metadata_fields(
  output_contract : String,
) -> Map[String, Json] {
  let fields : Map[String, Json] = {}
  fields["preferred_skills"] = review_preferred_skills().to_json()
  fields["execution_mode"] = "acp".to_json()
  fields["execution_target"] = review_execution_target().to_json()
  fields["output_contract"] = output_contract.to_json()
  @moonclaw_policy.add_no_input_policy(fields)
  fields
}
