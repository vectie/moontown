///|
async fn write_book_quality_review_moonclaw_profile(
  review_dir : String,
) -> Unit {
  let root = book_quality_review_root(review_dir)
  write_text_file(
    "\{root}/moonclaw.jobs.json",
    book_quality_review_moonclaw_profile_json().stringify(indent=2),
  )
  let home = "\{root}/.moonclaw"
  let config_path = "\{home}/moonclaw.json"
  write_text_file(
    config_path,
    book_quality_review_acp_config_json().stringify(indent=2),
  )
}

///|
fn book_quality_review_moonclaw_profile_json() -> Json {
  let profiles : Map[String, Json] = {}
  profiles[book_quality_review_profile_id()] = book_quality_review_profile_json()
  { "jobs": { "profiles": Json::object(profiles) } }
}

///|
fn book_quality_review_profile_json() -> Json {
  {
    "family": book_quality_review_profile_id(),
    "role": "reviewer",
    "priority": 170,
    "tags": ["book-quality", "ai-review", "semantic-review"],
    "match": {
      "all": ["book-quality", "ai-review"],
      "any": book_quality_reviewable_types(),
    },
    "steps": [book_quality_review_step_json()],
  }
}

///|
fn book_quality_review_step_json() -> Json {
  {
    "id": "review_book_semantic_quality",
    "title": "Review one MoonBook workspace for real semantic quality",
    "kind": "job.analysis",
    "prompt_template": "Read ${proposal.request_text}. Read all absolute context_pages and skill_paths. Return exactly the requested book quality AI review contract. Do not write files.",
    "metadata": book_quality_review_profile_step_metadata_json(),
  }
}

///|
fn book_quality_review_packet_step_metadata_json(
  output_contract : String,
) -> Json {
  let metadata = book_quality_review_execution_metadata(output_contract)
  metadata["kind"] = "book_quality_ai_review".to_json()
  Json::object(metadata)
}

///|
fn book_quality_review_profile_step_metadata_json() -> Json {
  let metadata = book_quality_review_execution_metadata(
    book_quality_review_output_contract(),
  )
  metadata["enable_tools"] = true.to_json()
  metadata["role_runtime"] = book_quality_review_role_runtime_json()
  Json::object(metadata)
}

///|
fn book_quality_review_execution_metadata(
  output_contract : String,
) -> Map[String, Json] {
  moonclaw_execution_metadata_fields(
    preferred_skills=book_quality_review_preferred_skills(),
    execution_mode="acp",
    execution_target=Some(book_quality_review_execution_target()),
    output_contract~,
  )
}

///|
fn book_quality_review_role_runtime_json() -> Json {
  {
    "planning_layer": "town-quality-governance",
    "runtime_mode": "semantic-review",
    "tool_access": "workspace-read",
    "memory_scope": "book-quality",
    "allow_delegate": false,
    "allow_workspace_write": false,
    "allow_execution_tools": true,
    "output_contract": book_quality_review_output_contract(),
  }
}

///|
fn book_quality_review_profile_id() -> String {
  "book_quality_ai_reviewer"
}

///|
fn book_quality_review_output_contract() -> String {
  "moontown.book_quality.ai_review.v1"
}

///|
fn book_quality_review_execution_target() -> String {
  "codex-main"
}

///|
fn book_quality_review_preferred_skills() -> Array[String] {
  ["book-quality-ai-review"]
}
