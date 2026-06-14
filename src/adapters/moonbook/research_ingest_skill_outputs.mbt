///|
fn research_ingest_required_raw_files_section() -> Array[String] {
  let lines = ["## Required Raw Files", ""]
  for bullet in @research_policy.ingest_required_raw_artifact_bullets("") {
    lines.push(bullet)
  }
  lines.push("")
  lines
}

///|
fn research_ingest_required_wiki_files_section(
  topic : String,
  display : String,
) -> Array[String] {
  [
    "## Required Wiki Files",
    "",
    "- `\{@research_policy.topic_source_page(topic)}` or another topic-specific verified source digest.",
    "- `\{@research_policy.topic_entity_page(topic)}` or another concrete entity page for \{display}.",
    "- `\{@research_policy.topic_concept_page(topic)}` or another concept page grounded in claims.",
    "- `\{@research_policy.topic_synthesis_page(topic)}` or another synthesis page connecting claims across sources.",
    "",
  ]
}

///|
fn research_ingest_verified_source_page_section() -> Array[String] {
  [
    "## Verified Source Page Criteria", "", "A page under `wiki/sources/` is verified only when it includes:",
    "", "- `Source type: verified source digest`", "- source IDs such as `W1`, `W2`, `L1`",
    "- inspected content summary", "- extracted claim IDs", "- confidence and risk notes",
    "- explicit blockers for missing web or local evidence", "",
  ]
}

///|
fn research_ingest_example_result_section(display : String) -> Array[String] {
  [
    "## Example Result Shape",
    "",
    "```md",
    "# \{display} Research Brief",
    "",
    "## Findings",
    research_ingest_example_finding(display),
    "",
    "## Contradictions",
    "- C2 has local support but no public source; confidence remains medium.",
    "",
    "## Gaps",
    "- Web tools were unavailable, so public-source verification is blocked.",
    "```",
    "",
  ]
}

///|
fn research_ingest_example_finding(display : String) -> String {
  research_ingest_text([
    "- C1: \{display} has a specific verified property. Evidence: W1 and W2",
    "if web was available, optional L1 only when local files are relevant.",
  ])
}
