///|
pub fn research_request_context_page() -> String {
  "raw/bootstrap/RESEARCH_REQUEST.md"
}

///|
pub fn source_hints_context_page() -> String {
  "raw/bootstrap/SOURCE_HINTS.md"
}

///|
pub fn reference_style_context_page() -> String {
  "raw/bootstrap/REFERENCE_STYLE.md"
}

///|
pub fn reference_output_context_page() -> String {
  "raw/bootstrap/REFERENCE_OUTPUT.md"
}

///|
pub fn reference_source_hints_context_page() -> String {
  "raw/bootstrap/REFERENCE_SOURCE_HINTS.md"
}

///|
pub fn journey_context_page() -> String {
  "wiki/history/journey.md"
}

///|
pub fn bootstrap_context_pages() -> Array[String] {
  [
    research_request_context_page(),
    source_hints_context_page(),
    reference_style_context_page(),
    reference_output_context_page(),
    reference_source_hints_context_page(),
  ]
}

///|
pub fn enrichment_context_pages() -> Array[String] {
  [
    research_request_context_page(),
    source_hints_context_page(),
    journey_context_page(),
  ]
}

///|
pub fn bootstrap_output_contract_lines() -> Array[String] {
  [
    "For direct Moontown research bootstrap worker steps, return plain Markdown summaries unless a step prompt explicitly asks for JSON.",
    "Do not return adaptive-planning JSON such as `needs_subplan` or `suggested_substeps`.",
    "Raw artifacts must be workspace-relative paths under `raw/bootstrap/`.",
    bootstrap_required_artifacts_contract(),
    "If any artifact cannot be produced, write a blocker artifact and explain the missing tool or source.",
  ]
}

///|
pub fn bootstrap_required_artifacts_contract() -> String {
  [
    "Required raw artifacts before the handoff is complete:",
    "\{raw_bootstrap_artifacts_sentence()}.",
  ].join(" ")
}
