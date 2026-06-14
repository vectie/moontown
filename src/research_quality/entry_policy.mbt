///|
pub fn research_quality_entry_is_research(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  @policy.catalog_entry_runs_research_evidence(entry.id, entry.name, entry.tags)
}

///|
fn research_quality_entry_is_wenyu_support(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  @civic.is_wenyu_book_entry(entry.id, entry.name, entry.tags)
}
