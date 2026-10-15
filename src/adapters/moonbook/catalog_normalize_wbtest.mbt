///|
test "an absolute Mac workspace path is retained by catalog normalization" {
  let entry = BookCatalogEntry::new(
    id="book-report",
    name="Report",
    purpose="Weekly report",
    workspace_root="/Users/example/Library/Application Support/MoonDesk/workspace/books/report",
  )
  assert_eq(normalize_catalog_entry(entry).workspace_root, entry.workspace_root)
  let legacy = { ..entry, workspace_root: "/workspace/books/report", }
  assert_eq(
    normalize_catalog_entry(legacy).workspace_root,
    default_workspace_root(entry.id),
  )
}
