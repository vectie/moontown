///|
pub fn default_planbook_book_id() -> String {
  "plan-moontown-quality"
}

///|
pub fn default_planbook_workspace_root() -> String {
  @moonbook.default_workspace_root(default_planbook_book_id())
}

///|
pub async fn bootstrap_moontown_planbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  let entry = planbook_catalog_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_single_book(catalog, entry),
  )
  write_planbook_workspace(entry)
  "Bootstrapped planbook `\{entry.id}` at \{workspace_root} and registered it in \{book_catalog_path}."
}

///|
pub async fn render_moontown_planbook_status(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  if @fs.exists("\{workspace_root}/wiki/index.md") {
    ensure_planbook_seed_files(workspace_root)
  }
  let missing = missing_planbook_workspace_required_paths(workspace_root)
  [
    "# Moontown Planbook Status",
    "",
    "- Book: `\{default_planbook_book_id()}`",
    "- Workspace: `\{workspace_root}`",
    "- Ready: `\{missing.is_empty()}`",
    "- Missing required: `\{missing.length()}`",
    "",
    "## Missing",
    "",
    if missing.is_empty() {
      "- none"
    } else {
      markdown_bullets(missing)
    },
  ].join("\n")
}
