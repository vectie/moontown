///|
fn research_ingest_header_section(display : String) -> Array[String] {
  [
    "---",
    "name: wiki-ingest",
    research_ingest_description(),
    "---",
    "",
    "# Wiki Ingest For \{display} Research",
    "",
    research_ingest_scope_rule(display),
    "",
  ]
}

///|
fn research_ingest_description() -> String {
  research_ingest_text([
    "description: Research-grade wiki ingest for a Moontown research book:", "search, screen, extract, materialize, and report blockers with provenance.",
  ])
}

///|
fn research_ingest_scope_rule(display : String) -> String {
  research_ingest_text([
    "This research book overrides the default generic wiki ingest behavior.",
    "Do not produce generic MoonBook product copy.",
    "Build a lane-specific research record for \{display}.",
  ])
}

///|
fn research_ingest_domain_guard_section(display : String) -> Array[String] {
  [
    "## Domain Guard",
    "",
    research_ingest_external_domain_rule(display),
    research_ingest_external_coverage_rule(),
    research_ingest_search_result_rule(),
    "",
  ]
}

///|
fn research_ingest_external_domain_rule(display : String) -> String {
  research_ingest_text([
    "- This lane is external domain research. Do not reinterpret \{display}",
    "as a local repo, Vectie project, or MoonBit package unless screened",
    "sources prove that meaning.",
  ])
}

///|
fn research_ingest_external_coverage_rule() -> String {
  research_ingest_text([
    "- Build source-backed coverage from web discovery, inspected pages,", "evidence extraction, raw worker artifacts, and durable MoonBook wiki pages.",
  ])
}

///|
fn research_ingest_search_result_rule() -> String {
  research_ingest_text([
    "- If a search tool returns only a search results page, fetch and screen", "that page or retry query variants before declaring a blocker.",
  ])
}
