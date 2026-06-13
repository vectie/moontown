///|
pub fn is_wenyu_book(entry : @moonbook.BookCatalogEntry) -> Bool {
  @civic.is_wenyu_book_entry(entry.id, entry.name, entry.tags)
}

///|
pub fn wenyu_module_name(entry : @moonbook.BookCatalogEntry) -> String {
  let prefix = "Wenyu Valley / "
  if entry.name.has_prefix(prefix) {
    entry.name.replace(old=prefix, new="")
  } else {
    entry.name
  }
}

///|
pub fn is_local_wenyu_build_fallback_task(kind : String) -> Bool {
  kind == "implementation-backlog" || kind == "image-asset"
}
