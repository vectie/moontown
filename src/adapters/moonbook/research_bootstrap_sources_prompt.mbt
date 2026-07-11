///|
fn research_bootstrap_sources_prompt() -> String {
  research_bootstrap_prompt([
    "Execute the source-screening stage of the imported MoonTown research bootstrap packet for ${proposal.title}.",
    research_bootstrap_source_screening_inputs_prompt(),
    "Do not load the full reference report in this source-screening stage; REFERENCE_STYLE.md already contains the style target and line count.",
    @research_policy.bootstrap_reference_policy_prompt(),
    @research_policy.bootstrap_native_web_policy_prompt(),
    @research_policy.bootstrap_command_fallback_policy_prompt(),
    @research_policy.bootstrap_source_depth_policy_prompt(),
    "Use high-signal URLs from SOURCE_HINTS.md and REFERENCE_SOURCE_HINTS.md as leads, but let the LLM choose which sources to include, exclude, or mark blocked.",
    "Use search pages only for discovery, never as claim evidence.",
    "Do not inspect local implementation files unless SOURCE_HINTS.md explicitly permits it.",
    research_bootstrap_source_screening_write_targets_prompt(),
    "Do not ask for more input; weak coverage is a blocker to record, not a reason to stall.",
    @research_policy.bootstrap_missing_source_policy_prompt(),
    @research_policy.bootstrap_plain_markdown_no_json_fields_prompt(),
    research_bootstrap_source_screening_return_prompt(),
  ])
}

///|
fn research_bootstrap_source_screening_return_prompt() -> String {
  research_bootstrap_prompt([
    "After these files are written, immediately return a concise completion summary.",
    "Include source counts, rejected sources, blockers, ready_for_12k_dossier, and whether synthesis has enough evidence.",
  ])
}

///|
fn research_bootstrap_source_screening_inputs_prompt() -> String {
  research_bootstrap_prompt([
    "Read raw/bootstrap/RESEARCH_REQUEST.md, raw/bootstrap/SOURCE_HINTS.md, \{@research_policy.question_path()}, and \{@research_policy.search_log_path()}.",
    "Also read optional raw/bootstrap/REFERENCE_STYLE.md and optional raw/bootstrap/REFERENCE_SOURCE_HINTS.md.",
    "Only read the relevant source-screening SKILL.md files.",
  ])
}

///|
fn research_bootstrap_source_screening_write_targets_prompt() -> String {
  "Write or revise \{@research_policy.search_log_path()}, \{@research_policy.source_screen_path()}, and \{@research_policy.tool_blockers_path()}."
}

///|
fn research_bootstrap_source_expansion_prompt() -> String {
  research_bootstrap_prompt([
    "Execute the focused source-expansion stage of the imported MoonTown research bootstrap packet for ${proposal.title}.",
    research_bootstrap_source_expansion_inputs_prompt(),
    "This step exists only to fix thin or weak source screens; do not write the final report.",
    "If \{@research_policy.source_screen_path()} already has \{@research_policy.min_included_sources()} or more included inspected evidence sources, verify the count, add a short no-op note to \{@research_policy.search_log_path()}, and finish.",
    "Otherwise, perform command-line fallback and source-domain front-door discovery now.",
    "You must call execute_command with bounded curl commands before returning when native search was weak.",
    "Fetch search-result pages when useful; if search pages block extraction, fetch source-domain front doors, robots.txt, sitemaps, and selected candidate content URLs.",
    @research_policy.bootstrap_source_expansion_harvest_policy_prompt(),
    "Convert fetched content pages into \{@research_policy.source_screen_path()} rows with include, exclude, discovery_only, or blocked decisions.",
    "Search/index/hub pages and sitemaps are not evidence unless they contain substantive inspected claims.",
    "Revise \{@research_policy.search_log_path()} with Command Fallback Attempts and harvested/fetched counts.",
    "Revise \{@research_policy.source_screen_path()} with accurate included_source_count and ready_for_12k_dossier.",
    "Revise \{@research_policy.tool_blockers_path()} with exact blocked source classes.",
    "If you still cannot reach \{@research_policy.min_included_sources()} included sources after command fallback and candidate conversion, record why; do not invent claims and do not ask for input.",
    "Return plain Markdown with included source count, command fallback count, fetched candidate count, blockers, and whether the next report step may target \{@research_policy.deep_dossier_word_target()}.",
  ])
}

///|
fn research_bootstrap_source_expansion_inputs_prompt() -> String {
  research_bootstrap_prompt([
    "Start by reading raw/bootstrap/RESEARCH_REQUEST.md, \{@research_policy.search_log_path()}, \{@research_policy.source_screen_path()}, and \{@research_policy.tool_blockers_path()}.",
    "Also read raw/bootstrap/SOURCE_HINTS.md and \{@research_policy.web_first_research_skill_path()}.",
  ])
}
