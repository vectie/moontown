///|
pub fn status_markdown(status : AppToolBookStatus) -> String {
  [
    "# App ToolBook Status",
    "",
    "- Book: `\{status.book_id}`",
    "- Workspace: `\{status.workspace_root}`",
    "- Ready: `\{status.ready}`",
    "- Catalog entry: `\{status.has_catalog_entry}`",
    "- Standing goal: `\{status.has_standing_goal}`",
    "- Standing goal enabled: `\{status.standing_goal_enabled}`",
    "- Tool manifest: `\{status.has_tool_manifest}`",
    "- Missing required: `\{status.missing_count}` / `\{status.required_count}`",
    "",
    "## Missing",
    "",
    if status.missing_paths.is_empty() {
      "- none"
    } else {
      markdown_bullets(status.missing_paths)
    },
  ].join("\n")
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  values.map(fn(value) { "- \{value}" }).join("\n")
}
