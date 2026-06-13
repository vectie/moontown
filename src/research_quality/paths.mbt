///|
fn research_quality_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
fn research_quality_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{research_quality_generated_site_path()}"
}

///|
fn path_basename(value : String) -> String {
  @path.Path::basename(value).to_owned()
}
