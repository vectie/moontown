///|
async fn normalize_book_state_summary(
  entry : BookCatalogEntry,
  external : ExternalBookStateSummary,
) -> BookStateSummary {
  let root = resolved_workspace_root(entry.workspace_root)
  let accounting = evidence_accounting_for_workspace(
    root,
    fallback_total=external.evidence_count,
  )
  let substantive_coverage_ready = external.substantive_coverage_ready &&
    accounting.domain_count > 0
  BookStateSummary::new(
    book_id=external.book_id,
    root=external.root,
    page_count=external.page_count,
    source_count=external.source_count,
    source_page_count=external.source_page_count,
    candidate_source_count=external.candidate_source_count,
    provisional_source_count=external.provisional_source_count,
    verified_source_count=external.verified_source_count,
    entity_count=external.entity_count,
    entity_page_count=external.entity_page_count,
    concept_count=external.concept_count,
    concept_page_count=external.concept_page_count,
    query_note_count=external.query_note_count,
    pending_review_count=external.pending_review_count,
    keeper_memory_count=external.keeper_memory_count,
    keeper_working_count=external.keeper_working_count,
    evidence_count=accounting.domain_count,
    total_evidence_count=accounting.total_count,
    operational_evidence_count=accounting.operational_count,
    substantive_coverage_ready~,
    summary=append_evidence_accounting_summary(external.summary, accounting),
  )
}
