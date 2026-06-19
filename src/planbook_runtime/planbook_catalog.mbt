///|
fn planbook_catalog_entry(
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=default_planbook_book_id(),
    name="MoonBook / Moontown Quality Planbook",
    purpose="Durable planbook for implementation plans, acceptance criteria, execution evidence, review notes, and stable-state handoffs for Moontown quality work.",
    workspace_root~,
    memory_scope=BookPrivate,
    tags=["planbook", "code-plan", "quality-gates", "implementation", "review"],
    skills=["code-plan", "code-review", "doc-sync", "acceptance-gates"],
  )
}

///|
fn merge_single_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  book : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id != book.id {
      merged.push(entry)
    }
  }
  merged.push(book)
  merged
}
