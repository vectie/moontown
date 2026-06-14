///|
pub fn bootstrap_quality_repair_expansion_axes_prompt() -> String {
  bootstrap_prompt_text([
    "Expand only from screened evidence.", "Add mechanism analysis, route-by-route sections, source-reliability analysis, and maturity/adoption filters.",
    "Also add bottlenecks, scenarios, second-order implications, what would change the thesis, and explicit evidence limits.",
  ])
}

///|
pub fn bootstrap_quality_repair_depth_prompt() -> String {
  bootstrap_prompt_text([
    bootstrap_quality_repair_length_policy_prompt(),
    "Use the tool-counted word count, not visual length; if the count is below \{repair_expansion_threshold()} and evidence exists, keep expanding from screened evidence until it is safely above \{quality_floor_count()}.",
    "If a long reference exists, also satisfy the reference line-count target.",
  ])
}

///|
pub fn bootstrap_quality_repair_length_policy_prompt() -> String {
  bootstrap_prompt_text([
    "For complex external, comparative, route-map, or technology research with \{min_included_sources()} or more included sources, revise \{deep_report_path()}.",
    "The target is a \{repair_dossier_word_target()} dossier.",
    "Keep a hard acceptance floor of \{repair_acceptance_floor()} unless the source-screen explicitly records a source-depth blocker.",
  ])
}
