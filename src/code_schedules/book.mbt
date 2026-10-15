///|
/// MoonDesk identifies a book workspace as `book-<id>` while MoonTown's
/// catalog stores the book's own id. Preserve exact matches for existing
/// schedules, then resolve the desktop workspace form.
pub fn find_code_schedule_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  workspace_id : String,
) -> @moonbook.BookCatalogEntry? {
  match @moonbook.find_catalog_entry(catalog, workspace_id) {
    Some(entry) => Some(entry)
    None =>
      match workspace_id.strip_prefix("book-") {
        Some(book_id) =>
          @moonbook.find_catalog_entry(catalog, book_id.to_owned())
        None => None
      }
  }
}
