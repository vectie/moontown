///|
fn web_first_example_workflow_section(
  topic : String,
  display : String,
  sample_query : String,
  sample_url : String,
) -> Array[String] {
  [
    "## Example Workflow",
    "",
    "Search sequence:",
    "- native mode: `web_search` query: `\{sample_query}`",
    "- native mode: `web_search` query: `\{research_followup_query(topic, display)}`",
    "- native mode: `web_search` query: `\{research_risk_query(topic, display)}`",
    web_first_example_search_page_command(sample_query),
    "- command-line mode: `curl -L --max-time 12 '\{sample_url}'`",
    "",
    "Then write protocol notes like:",
    "",
    "```md",
    "# Search Log",
    "",
    "| ID | Query | Selected source | Decision | Rationale |",
    "| --- | --- | --- | --- | --- |",
    web_first_example_search_log_row(sample_query, sample_url, display),
    "",
    "# Evidence Matrix",
    "",
    "| Claim ID | Claim | Sources | Confidence | Notes |",
    "| --- | --- | --- | --- | --- |",
    web_first_example_evidence_matrix_row(display),
    "```",
    "",
    web_first_example_handoff_rule(),
    "",
  ]
}

///|
fn web_first_example_search_page_command(sample_query : String) -> String {
  web_first_text([
    "- command-line mode: `curl -L --max-time 12 'search page chosen by the",
    "worker for \{sample_query}'`",
  ])
}

///|
fn web_first_example_search_log_row(
  sample_query : String,
  sample_url : String,
  display : String,
) -> String {
  web_first_text([
    "| W1 | `\{sample_query}` | `\{sample_url}` | include | inspected source",
    "with direct relevance to \{display} |",
  ])
}

///|
fn web_first_example_evidence_matrix_row(display : String) -> String {
  web_first_text([
    "| C1 | \{display} has a specific verified property discovered from",
    "screened evidence. | W1 | medium | Confirm with another current source",
    "before final synthesis. |",
  ])
}

///|
fn web_first_example_handoff_rule() -> String {
  web_first_text([
    "Do not stop after the notes. Use them to drive either durable wiki pages", "or a clear handoff that MoonBook can materialize.",
  ])
}
