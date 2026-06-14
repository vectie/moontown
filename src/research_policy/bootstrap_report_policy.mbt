///|
pub fn bootstrap_report_repair_policy_prompt() -> String {
  bootstrap_prompt_text([
    "If raw/bootstrap/QUALITY_REPAIR.md exists and says `No active quality repair`, treat it as historical audit context only.",
    bootstrap_active_repair_policy_prompt(),
  ])
}

///|
pub fn bootstrap_active_repair_policy_prompt() -> String {
  bootstrap_prompt_text([
    "If raw/bootstrap/QUALITY_REPAIR.md exists with active gaps and \{deep_report_path()} already exists, treat this as repair mode.",
    "Do not rewrite deep-report.md from scratch in this report stage.",
    "preserve the existing report structure and claims.",
    "Refresh only obviously stale companion artifacts.",
    "Leave length expansion or detailed review to research_bootstrap_quality_repair unless deep-report.md is missing.",
  ])
}

///|
pub fn bootstrap_report_evidence_policy_prompt() -> String {
  bootstrap_prompt_text([
    "Use the screened sources and blockers as the evidence boundary, even if the source set is thin.",
    bootstrap_reference_evidence_boundary_prompt(),
    "Treat reference source hints only as already-screened lead metadata; if a hinted source was not screened, it belongs in Evidence and Limits, not in claims.",
  ])
}

///|
pub fn bootstrap_reference_evidence_boundary_prompt() -> String {
  bootstrap_prompt_text([
    "Treat reference output as a style, language, structure, length, candidate-route taxonomy, and visualization target only.",
    "Do not copy its domain claims unless independently supported by screened sources for this topic.",
  ])
}

///|
pub fn bootstrap_report_quality_target_prompt() -> String {
  bootstrap_prompt_text([
    bootstrap_no_reference_quality_authority_prompt(),
    "If the source base is too thin for that length, write the best honest draft and explicitly name which source classes prevent full depth.",
  ])
}

///|
pub fn bootstrap_no_reference_quality_authority_prompt() -> String {
  bootstrap_prompt_text([
    "If no reference report exists, use `\{research_report_skill_path()}` as the quality authority.",
    "For complex external, comparative, route-map, or technology research with \{min_included_sources()} or more included sources, the draft should aim for a \{repair_dossier_word_target()} deep dossier.",
    "Do not collapse that case into a short executive article.",
    "\{quality_floor_words()} is only the acceptance floor, so aim above it to avoid near-miss drafts.",
  ])
}

///|
pub fn bootstrap_report_self_review_prompt() -> String {
  bootstrap_prompt_text([
    "Before returning, perform a tool-backed self-review of deep-report.md.", "Count English words, section headings, included screened sources, tables, Mermaid blocks, topic correctness, and process-log leakage.",
    "If any fixable quality gap remains, revise the report in-place immediately instead of leaving the issue for the review stage.",
  ])
}
