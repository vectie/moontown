///|
pub struct ResearchReadiness {
  book_id : String
  root : String
  source_page_count : Int
  verified_source_count : Int
  entity_page_count : Int
  concept_page_count : Int
  query_note_count : Int
  evidence_count : Int
  pending_review_count : Int
  substantive_coverage_ready : Bool
  gaps : Array[String]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn ResearchReadiness::from_summary(
  summary : @moonbook.BookStateSummary,
  extra_gaps? : Array[String] = [],
) -> ResearchReadiness {
  let gaps = extra_gaps.copy()
  if summary.verified_source_count == 0 {
    gaps.push("no verified source pages")
  }
  if summary.evidence_count == 0 {
    gaps.push("no durable evidence records")
  }
  if summary.entity_page_count == 0 {
    gaps.push("no entity pages")
  }
  if summary.concept_page_count == 0 {
    gaps.push("no concept pages")
  }
  if summary.pending_review_count > 0 {
    gaps.push("\{summary.pending_review_count} pending review item(s)")
  }
  let substantive_coverage_ready = gaps.is_empty() &&
    summary.verified_source_count > 0 &&
    summary.evidence_count > 0 &&
    summary.entity_page_count > 0 &&
    summary.concept_page_count > 0
  {
    book_id: summary.book_id,
    root: summary.root,
    source_page_count: summary.source_page_count,
    verified_source_count: summary.verified_source_count,
    entity_page_count: summary.entity_page_count,
    concept_page_count: summary.concept_page_count,
    query_note_count: summary.query_note_count,
    evidence_count: summary.evidence_count,
    pending_review_count: summary.pending_review_count,
    substantive_coverage_ready,
    gaps,
  }
}

///|
pub fn ResearchReadiness::summary_line(self : ResearchReadiness) -> String {
  let status = if self.substantive_coverage_ready {
    "ready"
  } else {
    "not-ready"
  }
  "\{self.book_id}: \{status}; sources=\{self.verified_source_count}; evidence=\{self.evidence_count}; entities=\{self.entity_page_count}; concepts=\{self.concept_page_count}; review=\{self.pending_review_count}"
}
