///|
fn research_ingest_mandatory_method_section() -> Array[String] {
  [
    "## Mandatory Method",
    "",
    "1. Read `raw/bootstrap/RESEARCH_REQUEST.md` and `raw/bootstrap/SOURCE_HINTS.md` first.",
    research_ingest_web_first_step(),
    research_ingest_question_step(),
    research_ingest_search_log_step(),
    research_ingest_source_screen_step(),
    research_ingest_evidence_matrix_step(),
    research_ingest_local_after_web_step(),
    research_ingest_marketing_brief_step(),
    "9. Materialize durable wiki pages only from screened evidence: `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, and `wiki/synthesis/`.",
    "10. Update `wiki/index.md` and `wiki/log.md` with the durable pages created.",
    "",
  ]
}

///|
fn research_ingest_web_first_step() -> String {
  research_ingest_text([
    "2. Attempt web-first discovery before local-only conclusions.",
    "Use native `web_search` and `web_fetch` when available.",
    "If they are unavailable, use bounded command-line discovery such as",
    "`curl -L --max-time 12`; if all web access is blocked, write",
    "`\{research_tool_blockers_path()}` and mark web evidence as blocked.",
  ])
}

///|
fn research_ingest_question_step() -> String {
  "3. Create `\{research_question_path()}` with question, scope, inclusion criteria, exclusion criteria, keywords, and source classes."
}

///|
fn research_ingest_search_log_step() -> String {
  "4. Create `\{research_search_log_path()}` even when web tools are blocked. Include attempted queries, selected or blocked URLs, rejected sources, and decisions."
}

///|
fn research_ingest_source_screen_step() -> String {
  "5. Create `\{research_source_screen_path()}` with source ID, include/exclude decision, authority, relevance, recency, and risk."
}

///|
fn research_ingest_evidence_matrix_step() -> String {
  "6. Create `\{research_evidence_matrix_path()}` before writing wiki prose. Claims must be falsifiable and cite source IDs."
}

///|
fn research_ingest_local_after_web_step() -> String {
  research_ingest_text([
    "7. Inspect local files only after recording the web-search state, and only",
    "when `SOURCE_HINTS.md` or screened web evidence makes local files relevant.",
    "Use exact paths and record them as `L1`, `L2`, etc.",
  ])
}

///|
fn research_ingest_marketing_brief_step() -> String {
  "8. Write `\{research_marketing_brief_path()}` from screened evidence using `skills/wiki-marketing/SKILL.md`; make it buyer-facing, specific, and proof-backed."
}
