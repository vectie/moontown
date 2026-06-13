///|
pub fn default_cookbook_book_id() -> String {
  default_book_id()
}

///|
pub fn default_cookbook_workspace_root() -> String {
  default_workspace_root()
}

///|
pub fn default_cookbook_manifest_path() -> String {
  default_manifest_path()
}

///|
pub fn cookbook_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
pub fn cookbook_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{cookbook_generated_site_path()}"
}

///|
pub fn cookbook_status_from_manifest(
  workspace_root : String,
  manifest_path : String,
  manifest : MoontownCookbookManifest,
  workspace_ready : Bool,
  manifest_exists : Bool,
) -> MoontownCookbookStatus {
  let summary = CookbookArtifactSummary::from_artifacts(manifest.artifacts)
  {
    book_id: default_cookbook_book_id(),
    workspace_root,
    manifest_path,
    docs_count: summary.docs_count,
    definition_count: summary.definition_count,
    runtime_state_count: summary.runtime_state_count,
    required_missing_count: summary.required_missing_count(),
    required_missing_paths: summary.required_missing_paths,
    ready: workspace_ready && manifest_exists,
  }
}
