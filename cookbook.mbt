///|
pub fn default_cookbook_book_id() -> String {
  @cookbook.default_book_id()
}

///|
pub fn default_cookbook_workspace_root() -> String {
  @cookbook.default_workspace_root()
}

///|
pub fn default_cookbook_manifest_path() -> String {
  @cookbook.default_manifest_path()
}

///|
pub async fn bootstrap_moontown_cookbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = default_cookbook_workspace_root(),
  manifest_path? : String = default_cookbook_manifest_path(),
) -> String {
  let entry = @cookbook.book_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    @cookbook.merge_catalog(catalog, entry),
  )
  let manifest = @cookbook.manifest(workspace_root, manifest_path)
  write_text_file(manifest_path, manifest.to_json().stringify(indent=2))
  @cookbook.write_workspace(entry, manifest)
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  "Bootstrapped MoonBook cookbook `\{entry.id}` at \{workspace_root}; wrote \{manifest_path}; required_missing=\{status.required_missing_count}."
}

///|
pub async fn inspect_moontown_cookbook(
  workspace_root? : String = default_cookbook_workspace_root(),
  manifest_path? : String = default_cookbook_manifest_path(),
) -> @cookbook.MoontownCookbookStatus {
  let manifest = @cookbook.manifest(workspace_root, manifest_path)
  let summary = @cookbook.CookbookArtifactSummary::from_artifacts(
    manifest.artifacts,
  )
  let workspace_ready = @fs.exists("\{workspace_root}/wiki/index.md") &&
    @fs.exists("\{workspace_root}/book/moonbook-ui-state.json")
  {
    book_id: default_cookbook_book_id(),
    workspace_root,
    manifest_path,
    docs_count: summary.docs_count,
    definition_count: summary.definition_count,
    runtime_state_count: summary.runtime_state_count,
    required_missing_count: summary.required_missing_count(),
    required_missing_paths: summary.required_missing_paths,
    ready: workspace_ready && @fs.exists(manifest_path),
  }
}

///|
pub async fn render_moontown_cookbook_status(
  workspace_root? : String = default_cookbook_workspace_root(),
  manifest_path? : String = default_cookbook_manifest_path(),
) -> String {
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  @cookbook.status_markdown(status)
}
