///|
fn research_bootstrap_quality_repair_prompt() -> String {
  research_bootstrap_prompt([
    "Execute the final deep-research review gate for ${proposal.title}.",
    research_bootstrap_quality_repair_inputs_prompt(),
    "Use tools to count English word tokens, lines, sections, tables, Mermaid blocks, and included source rows.",
    "If raw/bootstrap/REFERENCE_OUTPUT.md exists, count its lines but do not load the full reference report unless REFERENCE_STYLE.md is insufficient.",
    "If no reference exists, do not ask for one; the skill is the quality contract.",
    "First judge whether the report already passes; if it passes, record a no-op review with measured counts and do not rewrite for churn.",
    "If fixable gaps remain, repair in-place in \{research_deep_report_path()} rather than creating v2/v3/v4 files or a new book.",
    research_bootstrap_quality_repair_depth_prompt(),
    research_bootstrap_quality_repair_expansion_axes_prompt(),
    "Do not add unsupported claims, do not copy reference facts, and do not hard-code topic facts outside screened evidence.",
    "Also revise \{research_marketing_brief_path()} only if the report title or thesis changed.",
    "Return plain Markdown with before/after word counts, line counts, section count, source count, whether repair was needed, and remaining quality gaps.",
  ])
}

///|
fn research_bootstrap_quality_repair_expansion_axes_prompt() -> String {
  research_bootstrap_prompt([
    "Expand only from screened evidence.", "Add mechanism analysis, route-by-route sections, source-reliability analysis, and maturity/adoption filters.",
    "Also add bottlenecks, scenarios, second-order implications, what would change the thesis, and explicit evidence limits.",
  ])
}

///|
fn research_bootstrap_quality_repair_inputs_prompt() -> String {
  research_bootstrap_prompt([
    "Read \{research_bootstrap_quality_repair_input_artifacts().join(", ")}.",
    "Also read optional raw/bootstrap/QUALITY_REPAIR.md, \{@research_policy.research_report_skill_path()}, and optional raw/bootstrap/REFERENCE_STYLE.md.",
  ])
}

///|
fn research_bootstrap_quality_repair_input_artifacts() -> Array[String] {
  [
    research_source_screen_path(),
    research_evidence_matrix_path(),
    research_synthesis_brief_path(),
    research_deep_report_path(),
    research_marketing_brief_path(),
  ]
}

///|
fn research_bootstrap_quality_repair_depth_prompt() -> String {
  research_bootstrap_prompt([
    research_bootstrap_quality_repair_length_policy_prompt(),
    "Use the tool-counted word count, not visual length; if the count is below \{@research_policy.repair_expansion_threshold()} and evidence exists, keep expanding from screened evidence until it is safely above \{@research_policy.quality_floor_count()}.",
    "If a long reference exists, also satisfy the reference line-count target.",
  ])
}

///|
fn research_bootstrap_quality_repair_length_policy_prompt() -> String {
  research_bootstrap_prompt([
    "For complex external, comparative, route-map, or technology research with \{@research_policy.min_included_sources()} or more included sources, revise \{research_deep_report_path()}.",
    "The target is a \{@research_policy.repair_dossier_word_target()} dossier.",
    "Keep a hard acceptance floor of \{@research_policy.repair_acceptance_floor()} unless the source-screen explicitly records a source-depth blocker.",
  ])
}
