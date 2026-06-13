///|
fn catalog_name(title : String) -> String {
  "MoonBook / App ToolBook / \{title}"
}

///|
fn catalog_tags() -> Array[String] {
  [
    "appbook", "standing-watch", "generated-tool", "web-tool-surface", "civic-building",
    "template:app-tool-book",
  ]
}

///|
fn catalog_skills() -> Array[String] {
  [
    "tool-watch", "tool-analysis", "tool-build", "tool-review", "notification-digest",
  ]
}

///|
pub fn catalog_entry(
  book_id : String,
  title : String,
  purpose : String,
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=book_id,
    name=catalog_name(title),
    purpose~,
    workspace_root~,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=catalog_tags(),
    skills=catalog_skills(),
  )
}
