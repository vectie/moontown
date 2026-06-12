///|
pub fn research_quality_gate_execution_summary(
  original_summary : String,
  gap_count : Int,
  auto_retry : Bool,
) -> String {
  "\{original_summary} / quality_gate_failed=\{gap_count} / auto_retry=\{auto_retry}"
}

///|
pub fn research_quality_gate_event_detail(
  book_id : String,
  gaps : Array[String],
  marked_count : Int,
) -> String {
  let gap_summary = gaps.join("; ")
  "Research quality gate failed for \{book_id}: \{gap_summary}; mayor marked \{marked_count} task(s) as review-queued and scheduled in-place repair retries when attempts remain."
}

///|
pub fn recovered_research_bootstrap_execution_summary(
  original_summary : String,
) -> String {
  "\{original_summary} / quality_gate_recovered=clean_research_projection"
}

///|
pub fn recovered_research_bootstrap_event_detail(book_id : String) -> String {
  "Research bootstrap for \{book_id} recovered after late worker failure because MoonBook artifacts, wiki materialization, and generated site passed quality gates."
}
