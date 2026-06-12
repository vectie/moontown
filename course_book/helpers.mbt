///|
fn merge_single_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  entry : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  let mut found = false
  for existing in catalog {
    if existing.id == entry.id {
      merged.push(entry)
      found = true
    } else {
      merged.push(existing)
    }
  }
  if !found {
    merged.push(entry)
  }
  merged
}
