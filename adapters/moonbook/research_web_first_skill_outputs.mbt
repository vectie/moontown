///|
fn web_first_required_output_section(display : String) -> Array[String] {
  [
    "## Required Output",
    "",
    web_first_research_question_output(),
    web_first_search_log_output(),
    web_first_source_screen_output(),
    web_first_evidence_matrix_output(),
    web_first_local_sources_output(),
    web_first_synthesis_brief_output(),
    web_first_deep_report_output(),
    web_first_marketing_brief_output(),
    web_first_wiki_materialization_output(display),
    "",
  ]
}

///|
fn web_first_research_question_output() -> String {
  "- `\{research_question_path()}` with scope and criteria."
}

///|
fn web_first_search_log_output() -> String {
  "- `\{research_search_log_path()}` with queries, selected URLs, rejected URLs, and reasons."
}

///|
fn web_first_source_screen_output() -> String {
  "- `\{research_source_screen_path()}` with authority, relevance, recency, and risk notes."
}

///|
fn web_first_evidence_matrix_output() -> String {
  web_first_text([
    "- `\{research_evidence_matrix_path()}` with claim IDs, source IDs,",
    "evidence, confidence, and gaps.",
  ])
}

///|
fn web_first_local_sources_output() -> String {
  web_first_text([
    "- `\{research_local_sources_path()}` with exact file paths, symbols or",
    "sections, and evidence bullets.",
  ])
}

///|
fn web_first_synthesis_brief_output() -> String {
  web_first_text([
    "- `\{research_synthesis_brief_path()}` with findings, contradictions,",
    "gaps, and next research.",
  ])
}

///|
fn web_first_deep_report_output() -> String {
  web_first_text([
    "- `\{research_deep_report_path()}` with thesis-first research analysis,",
    "tables, Mermaid relationship diagram, maturity assessment, and evidence",
    "limits.",
  ])
}

///|
fn web_first_marketing_brief_output() -> String {
  web_first_text([
    "- `\{research_marketing_brief_path()}` with buyer-facing positioning,",
    "product strengths, proof points, objections, and next action.",
  ])
}

///|
fn web_first_wiki_materialization_output(display : String) -> String {
  web_first_text([
    "- Wiki-ready materialization notes that are specific to \{display};",
    "create durable wiki pages only when the current runtime owns MoonBook",
    "wiki materialization.",
  ])
}

///|
fn web_first_deep_dossier_section() -> Array[String] {
  [
    "## Deep Dossier Target",
    "",
    web_first_deep_dossier_intent(),
    "",
    web_first_preferred_source_base_rule(),
    web_first_minimum_source_base_rule(),
    "- target report size with enough evidence: 12k-15k English words",
    web_first_honest_depth_limit_rule(),
    "",
  ]
}

///|
fn web_first_deep_dossier_intent() -> String {
  web_first_text([
    "For complex external, comparative, route-map, or technology research,", "source collection should be strong enough to support a long-form dossier,",
    "not just a short article.",
  ])
}

///|
fn web_first_preferred_source_base_rule() -> String {
  web_first_text([
    "- preferred source base: \{web_first_preferred_included_sources_text()} included, inspected sources",
    "across \{web_first_extended_source_classes()} classes",
  ])
}

///|
fn web_first_minimum_source_base_rule() -> String {
  web_first_text([
    "- minimum source base for a cautious dossier: \{web_first_minimum_included_sources_text()} included, inspected",
    "sources plus explicit blockers for missing classes",
  ])
}

///|
fn web_first_honest_depth_limit_rule() -> String {
  web_first_text([
    "- if this target cannot be reached honestly, write the source-depth", "blocker, set `ready_for_12k_dossier: false`, and write the next search",
    "plan; do not pad with generic definitions",
  ])
}
