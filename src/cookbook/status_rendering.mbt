///|
pub fn status_markdown(status : MoontownCookbookStatus) -> String {
  [
    "# MoonTown Cookbook Status",
    "",
    "- Book: `\{status.book_id}`",
    "- Workspace: `\{status.workspace_root}`",
    "- Manifest: `\{status.manifest_path}`",
    "- Ready: `\{status.ready}`",
    "- Docs tracked: `\{status.docs_count}`",
    "- Definitions tracked: `\{status.definition_count}`",
    "- Runtime states tracked: `\{status.runtime_state_count}`",
    "- Required missing: `\{status.required_missing_count}`",
    "",
    "## Required Missing Paths",
    "",
    required_missing_paths_markdown(status.required_missing_paths),
  ].join("\n")
}

///|
fn required_missing_paths_markdown(paths : Array[String]) -> String {
  if paths.is_empty() {
    "- none"
  } else {
    let rows : Array[String] = []
    for path in paths {
      rows.push("- `\{path}`")
    }
    rows.join("\n")
  }
}
