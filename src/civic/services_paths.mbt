///|
pub fn civic_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
pub fn civic_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{civic_generated_site_path()}"
}
