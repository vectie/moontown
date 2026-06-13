///|
pub fn wenyu_build_skill_path() -> String {
  "skills/wenyu-build/SKILL.md"
}

///|
pub fn wenyu_code_patch_skill_path() -> String {
  "skills/wenyu-code-patch/SKILL.md"
}

///|
pub fn wenyu_asset_pack_skill_path() -> String {
  "skills/wenyu-asset-pack/SKILL.md"
}

///|
pub fn wenyu_civic_service_skill_path() -> String {
  "skills/wenyu-civic-service/SKILL.md"
}

///|
pub fn wenyu_base_skill_paths() -> Array[String] {
  [
    wenyu_build_skill_path(),
    wenyu_code_patch_skill_path(),
    wenyu_asset_pack_skill_path(),
    @research_policy.web_first_research_skill_path(),
    @research_policy.evidence_synthesis_skill_path(),
    @research_policy.repo_source_materialize_skill_path(),
    @research_policy.wiki_marketing_skill_path(),
  ]
}

///|
pub fn wenyu_civic_skill_paths(
  extra_skill_paths : Array[String],
) -> Array[String] {
  [wenyu_civic_service_skill_path(), ..extra_skill_paths]
}

///|
pub fn wenyu_prd_path() -> String {
  "raw/bootstrap/WENYU_VALLEY_PRD.md"
}

///|
pub fn wenyu_vision_path() -> String {
  "raw/bootstrap/WENYU_VISION.md"
}

///|
pub fn wenyu_build_report_path() -> String {
  @research_policy.deep_report_path()
}

///|
pub fn wenyu_evidence_matrix_path() -> String {
  @research_policy.evidence_matrix_path()
}

///|
pub fn wenyu_marketing_brief_path() -> String {
  @research_policy.marketing_brief_path()
}

///|
pub fn wenyu_local_sources_path() -> String {
  @research_policy.local_sources_path()
}

///|
pub fn wenyu_mounted_sources_manifest_path() -> String {
  "mounted-sources/MANIFEST.md"
}

///|
pub fn wenyu_implementation_backlog_path() -> String {
  "build/IMPLEMENTATION_BACKLOG.md"
}

///|
pub fn wenyu_acceptance_tests_path() -> String {
  "build/ACCEPTANCE_TESTS.md"
}

///|
pub fn wenyu_base_context_pages() -> Array[String] {
  [
    @research_policy.research_request_context_page(),
    @research_policy.source_hints_context_page(),
    wenyu_prd_path(),
    wenyu_vision_path(),
    wenyu_build_report_path(),
    wenyu_evidence_matrix_path(),
    wenyu_marketing_brief_path(),
    wenyu_local_sources_path(),
    wenyu_mounted_sources_manifest_path(),
    wenyu_implementation_backlog_path(),
    wenyu_acceptance_tests_path(),
  ]
}

///|
pub fn wenyu_civic_service_contract_path() -> String {
  "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md"
}

///|
pub fn wenyu_moonbook_ui_state_path() -> String {
  "book/moonbook-ui-state.json"
}

///|
pub fn wenyu_civic_context_pages() -> Array[String] {
  [wenyu_civic_service_contract_path(), wenyu_moonbook_ui_state_path()]
}

///|
pub fn wenyu_civic_output_contract_lines() -> Array[String] {
  [
    "civic_service_decision: update | no_change | needs_review | blocked", "book_changed: yes | no",
    "wiki_pages_changed_count: <integer>", "changed_pages: comma-separated durable page paths, or none",
    "accepted_facts_count: <integer>", "review_items_created_count: <integer>", "review_items: comma-separated review item ids/paths, or none",
    "projection_updated: yes | no", "projection_delta: one sentence explaining the projection-safe change, or blocked:<reason>",
    "protocol_decision_basis: one sentence naming the evidence, ledger, or blocker basis for the decision",
    "next_check_hint: normal | faster | slower | review",
  ]
}
