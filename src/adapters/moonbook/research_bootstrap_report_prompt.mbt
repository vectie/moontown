///|
fn research_bootstrap_report_prompt() -> String {
  research_bootstrap_prompt([
    "Execute the synthesis stage of the imported Moontown research bootstrap packet for ${proposal.title}.",
    research_bootstrap_report_inputs_prompt(),
    research_bootstrap_report_repair_policy_prompt(),
    "Do not load the full raw/bootstrap/REFERENCE_OUTPUT.md in this draft stage; use REFERENCE_STYLE.md for language, length class, and visual/table expectations when it exists.",
    "Read only the directly relevant synthesis/report/marketing SKILL.md files.",
    "Do not run new web discovery in this stage and do not ask for more input.",
    research_bootstrap_report_evidence_policy_prompt(),
    research_bootstrap_report_quality_target_prompt(),
    "Write analysis, route mechanics, evidence interpretation, adoption logic, and limits.",
    research_bootstrap_report_artifact_targets_prompt(),
    "If evidence is weak, write a cautious report with explicit Evidence and Limits, missing-source blockers, and next research; do not stall waiting for stronger evidence.",
    "The report must be topic-correct, source-backed, thesis-first, evidence-limited, and governed by the loaded research skills.",
    research_bootstrap_report_self_review_prompt(),
    "Do not reinterpret external domain topics as local repositories unless screened sources prove that meaning.",
    "Do not update wiki pages in this worker stage; raw artifacts are the handoff for MoonBook materialization.",
    research_bootstrap_plain_markdown_no_json_fields_prompt(),
    research_bootstrap_report_return_prompt(),
  ])
}

///|
fn research_bootstrap_report_artifact_targets_prompt() -> String {
  research_bootstrap_prompt([
    "Write or revise these raw/bootstrap artifacts:",
    research_bootstrap_report_artifact_targets().join(", ") + ".",
  ])
}

///|
fn research_bootstrap_report_artifact_targets() -> Array[String] {
  [
    research_local_sources_path(),
    research_evidence_matrix_path(),
    research_synthesis_brief_path(),
    research_deep_report_path(),
    research_marketing_brief_path(),
  ]
}

///|
fn research_bootstrap_report_return_prompt() -> String {
  research_bootstrap_prompt([
    "After the files are written and self-reviewed, immediately return the artifact paths.",
    "Include source counts, blockers, report word count, report quality gaps if any, and whether the evidence is strong enough for MoonBook wiki materialization.",
  ])
}

///|
fn research_bootstrap_report_inputs_prompt() -> String {
  research_bootstrap_prompt([
    "Start by reading \{research_bootstrap_report_input_artifacts().join(", ")}.",
    "Also read raw/bootstrap/RESEARCH_REQUEST.md and raw/bootstrap/SOURCE_HINTS.md.",
    "Also read optional raw/bootstrap/REFERENCE_SOURCE_HINTS.md, optional raw/bootstrap/REFERENCE_STYLE.md, and optional raw/bootstrap/QUALITY_REPAIR.md.",
  ])
}

///|
fn research_bootstrap_report_input_artifacts() -> Array[String] {
  [
    research_source_screen_path(),
    research_search_log_path(),
    research_tool_blockers_path(),
    research_question_path(),
  ]
}

///|
fn research_bootstrap_report_repair_policy_prompt() -> String {
  research_bootstrap_prompt([
    "If raw/bootstrap/QUALITY_REPAIR.md exists and says `No active quality repair`, treat it as historical audit context only.",
    research_bootstrap_active_repair_policy_prompt(),
  ])
}

///|
fn research_bootstrap_active_repair_policy_prompt() -> String {
  research_bootstrap_prompt([
    "If raw/bootstrap/QUALITY_REPAIR.md exists with active gaps and \{research_deep_report_path()} already exists, treat this as repair mode.",
    "Do not rewrite deep-report.md from scratch in this report stage.",
    "preserve the existing report structure and claims.",
    "Refresh only obviously stale companion artifacts.",
    "Leave length expansion or detailed review to research_bootstrap_quality_repair unless deep-report.md is missing.",
  ])
}

///|
fn research_bootstrap_report_evidence_policy_prompt() -> String {
  research_bootstrap_prompt([
    "Use the screened sources and blockers as the evidence boundary, even if the source set is thin.",
    research_bootstrap_reference_evidence_boundary_prompt(),
    "Treat reference source hints only as already-screened lead metadata; if a hinted source was not screened, it belongs in Evidence and Limits, not in claims.",
  ])
}

///|
fn research_bootstrap_reference_evidence_boundary_prompt() -> String {
  research_bootstrap_prompt([
    "Treat reference output as a style, language, structure, length, candidate-route taxonomy, and visualization target only.",
    "Do not copy its domain claims unless independently supported by screened sources for this topic.",
  ])
}

///|
fn research_bootstrap_report_quality_target_prompt() -> String {
  research_bootstrap_prompt([
    research_bootstrap_no_reference_quality_authority_prompt(),
    "If the source base is too thin for that length, write the best honest draft and explicitly name which source classes prevent full depth.",
  ])
}

///|
fn research_bootstrap_no_reference_quality_authority_prompt() -> String {
  research_bootstrap_prompt([
    "If no reference report exists, use `\{@research_policy.research_report_skill_path()}` as the quality authority.",
    "For complex external, comparative, route-map, or technology research with \{@research_policy.min_included_sources()} or more included sources, the draft should aim for a \{@research_policy.repair_dossier_word_target()} deep dossier.",
    "Do not collapse that case into a short executive article.",
    "\{@research_policy.quality_floor_words()} is only the acceptance floor, so aim above it to avoid near-miss drafts.",
  ])
}

///|
fn research_bootstrap_report_self_review_prompt() -> String {
  research_bootstrap_prompt([
    "Before returning, perform a tool-backed self-review of deep-report.md.", "Count English words, section headings, included screened sources, tables, Mermaid blocks, topic correctness, and process-log leakage.",
    "If any fixable quality gap remains, revise the report in-place immediately instead of leaving the issue for the review stage.",
  ])
}
