///|
fn catalog_entry_book_type(entry : BookCatalogEntry) -> String {
  @policy.catalog_entry_type(entry.id, entry.name, entry.tags)
}

///|
fn catalog_entry_is_research(entry : BookCatalogEntry) -> Bool {
  catalog_entry_book_type(entry) == @policy.research_type()
}

///|
fn catalog_entry_is_civic(entry : BookCatalogEntry) -> Bool {
  catalog_entry_book_type(entry) == @policy.civic_type()
}
