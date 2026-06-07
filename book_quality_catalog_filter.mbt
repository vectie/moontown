///|
fn book_quality_active_catalog_entry(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  !book_quality_archived_catalog_entry(entry) &&
  !book_quality_transient_catalog_entry(entry)
}

///|
fn book_quality_archived_catalog_entry(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  entry.tags.contains("archived") ||
  entry.tags.contains("hidden") ||
  entry.tags.contains("internal")
}

///|
fn book_quality_transient_catalog_entry(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  let id = entry.id.to_lower()
  let name = entry.name.to_lower()
  let purpose = entry.purpose.to_lower()
  id.contains("smoke") ||
  name.contains("smoke") ||
  purpose.contains("smoke test") ||
  purpose.contains("smoke-test")
}
