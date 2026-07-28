///|
pub async fn build_workspace(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> String {
  ensure_workspace(entry, moonbook_root~)
  let root = resolved_workspace_root(entry.workspace_root)
  let resolved_moonbook_root = resolved_root_path(moonbook_root)
  let (command, args) = moonbook_runtime_invocation(["build", root])
  ignore(
    @integration.run_checked(command, args, cwd=Some(resolved_moonbook_root)),
  )
  resolved_generated_site_index_after_build(root)
}

///|
pub fn generated_site_index_path(entry : BookCatalogEntry) -> String {
  canonical_generated_site_path(resolved_workspace_root(entry.workspace_root))
}

///|
pub fn workspace_root(entry : BookCatalogEntry) -> String {
  resolved_workspace_root(entry.workspace_root)
}
