///|
fn research_bootstrap_report_prompt() -> String {
  research_bootstrap_prompt([
    "Execute the synthesis stage of the imported MoonTown research bootstrap packet for ${proposal.title}.",
    research_bootstrap_report_inputs_prompt(),
    @research_policy.bootstrap_report_repair_policy_prompt(),
    "Do not load the full raw/bootstrap/REFERENCE_OUTPUT.md in this draft stage; use REFERENCE_STYLE.md for language, length class, and visual/table expectations when it exists.",
    "Read only the directly relevant synthesis/report/marketing SKILL.md files.",
    "Do not run new web discovery in this stage and do not ask for more input.",
    @research_policy.bootstrap_report_evidence_policy_prompt(),
    @research_policy.bootstrap_report_quality_target_prompt(),
    "Write analysis, route mechanics, evidence interpretation, adoption logic, and limits.",
    research_bootstrap_report_artifact_targets_prompt(),
    "If evidence is weak, write a cautious report with explicit Evidence and Limits, missing-source blockers, and next research; do not stall waiting for stronger evidence.",
    "The report must be topic-correct, source-backed, thesis-first, evidence-limited, and governed by the loaded research skills.",
    @research_policy.bootstrap_report_self_review_prompt(),
    "Do not reinterpret external domain topics as local repositories unless screened sources prove that meaning.",
    "Do not update wiki pages in this worker stage; raw artifacts are the handoff for MoonBook materialization.",
    @research_policy.bootstrap_plain_markdown_no_json_fields_prompt(),
    research_bootstrap_report_return_prompt(),
  ])
}

///|
fn research_bootstrap_report_artifact_targets_prompt() -> String {
  research_bootstrap_prompt([
    "Write or revise these raw/bootstrap artifacts:",
    @research_policy.bootstrap_report_artifact_targets().join(", ") + ".",
  ])
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
    "Start by reading \{@research_policy.bootstrap_report_input_artifacts().join(", ")}.",
    "Also read raw/bootstrap/RESEARCH_REQUEST.md and raw/bootstrap/SOURCE_HINTS.md.",
    "Also read optional raw/bootstrap/REFERENCE_SOURCE_HINTS.md, optional raw/bootstrap/REFERENCE_STYLE.md, and optional raw/bootstrap/QUALITY_REPAIR.md.",
  ])
}
