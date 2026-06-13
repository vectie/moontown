///|
fn research_quality_entry_type(entry : @moonbook.BookCatalogEntry) -> String {
  @policy.catalog_entry_type(entry.id, entry.name, entry.tags)
}

///|
pub fn research_quality_entry_is_research(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  research_quality_entry_type(entry) == @policy.research_type()
}

///|
fn research_quality_entry_is_wenyu_support(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  entry.id.has_prefix("wenyu-")
}
