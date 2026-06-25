///|
async fn normalize_book_state_summary(
  entry : BookCatalogEntry,
  summary : BookStateSummary,
) -> BookStateSummary {
  let root = resolved_workspace_root(entry.workspace_root)
  let accounting = evidence_accounting_for_workspace(
    root,
    fallback_total=summary.total_evidence_count,
  )
  let substantive_coverage_ready = summary.substantive_coverage_ready &&
    accounting.domain_count > 0
  BookStateSummary::new(
    book_id=summary.book_id,
    root=summary.root,
    page_count=summary.page_count,
    source_count=summary.source_count,
    source_page_count=summary.source_page_count,
    candidate_source_count=summary.candidate_source_count,
    provisional_source_count=summary.provisional_source_count,
    verified_source_count=summary.verified_source_count,
    entity_count=summary.entity_count,
    entity_page_count=summary.entity_page_count,
    concept_count=summary.concept_count,
    concept_page_count=summary.concept_page_count,
    query_note_count=summary.query_note_count,
    pending_review_count=summary.pending_review_count,
    keeper_memory_count=summary.keeper_memory_count,
    keeper_working_count=summary.keeper_working_count,
    evidence_count=accounting.domain_count,
    total_evidence_count=accounting.total_count,
    operational_evidence_count=accounting.operational_count,
    substantive_coverage_ready~,
    summary=append_evidence_accounting_summary(summary.summary, accounting),
  )
}
