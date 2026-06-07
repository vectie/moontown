///|
fn research_source_diarize_skill_text(entry : BookCatalogEntry) -> String {
  let display = display_topic_name(research_topic_id(entry))
  research_source_diarize_page(
    [
      "---",
      "name: source-diarize",
      research_source_diarize_description(),
      "---",
      "",
      "# Source Diarize For \{display}",
      "",
      research_source_diarize_scope(),
      "",
    ],
    display,
  )
}

///|
fn research_source_diarize_description() -> String {
  research_ingest_text([
    "description: Convert inspected web and local sources into claim-level", "research packets with screen decisions, provenance, and blockers.",
  ])
}

///|
fn research_source_diarize_scope() -> String {
  research_ingest_text([
    "Use this skill during bootstrap gather and materialization.", "The goal is not to list files.",
    "The goal is to turn inspected evidence into a reproducible research trail.",
  ])
}

///|
fn research_source_diarize_page(
  header : Array[String],
  display : String,
) -> String {
  let lines = header.copy()
  research_ingest_push(lines, research_source_id_section())
  research_ingest_push(lines, research_source_packet_requirements_section())
  research_ingest_push(lines, research_source_evidence_matrix_example(display))
  research_ingest_push(lines, research_source_do_not_section())
  lines.join("\n")
}

///|
fn research_source_id_section() -> Array[String] {
  [
    "## Source IDs", "", "- `W1`, `W2`, `W3`: web sources from search/fetch.", "- `L1`, `L2`, `L3`: local files only when local evidence is explicitly relevant.",
    "- `B1`: blocker records such as missing web search, unreadable file, or unavailable source.",
    "",
  ]
}

///|
fn research_source_packet_requirements_section() -> Array[String] {
  [
    "## Packet Requirements", "", "For each source packet or durable source page, include:",
    "", "- source ID", "- source type: web, local, or blocker", "- exact URL or local path",
    "- why it was included or excluded", "- extracted claims with IDs", "- confidence",
    "- risks or contradictions", "",
  ]
}

///|
fn research_source_evidence_matrix_example(display : String) -> Array[String] {
  [
    "## Evidence Matrix Example",
    "",
    "```md",
    "| Claim ID | Claim | Source IDs | Evidence detail | Confidence | Gap or contradiction |",
    "| --- | --- | --- | --- | --- | --- |",
    research_source_evidence_matrix_example_row(display),
    "```",
    "",
  ]
}

///|
fn research_source_evidence_matrix_example_row(display : String) -> String {
  research_ingest_text([
    "| C1 | \{display} has a specific verified property stated as a falsifiable",
    "sentence. | W1, W2 | Inspected sources support the claim; blocker rows",
    "explain missing evidence. | medium | Needs another independent source or",
    "narrower jurisdiction note. |",
  ])
}

///|
fn research_source_do_not_section() -> Array[String] {
  [
    "## Do Not",
    "",
    "- Do not create a verified source page from a candidate URL list alone.",
    "- Do not write only `moon.mod.json` metadata unless that is the actual research question.",
    "- Do not use the same generic product text across Moontown, MoonBook, and MoonClaw lanes.",
    "- Do not omit `\{research_search_log_path()}` just because web tools are missing.",
  ]
}
