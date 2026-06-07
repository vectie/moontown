///|
pub async fn inspect_app_tool_book(
  book_id? : String = default_app_tool_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> AppToolBookStatus {
  let root = app_tool_book_resolved_workspace_root(book_id, workspace_root)
  let required = app_tool_book_required_paths()
  let missing = missing_app_tool_book_required_paths(root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let has_catalog_entry = @moonbook.entry_for_book_id(catalog, book_id)
    is Some(_)
  let goal_id = app_tool_book_goal_id(book_id)
  let has_standing_goal = app_tool_book_goal_in(goals, goal_id)
  let standing_goal_enabled = app_tool_book_goal_enabled_in(goals, goal_id)
  let has_tool_manifest = @fs.exists("\{root}/tool-manifest.json")
  {
    book_id,
    workspace_root: root,
    required_count: required.length(),
    missing_count: missing.length(),
    missing_paths: missing,
    has_catalog_entry,
    has_standing_goal,
    standing_goal_enabled,
    has_tool_manifest,
    ready: missing.is_empty() &&
    has_catalog_entry &&
    has_standing_goal &&
    standing_goal_enabled &&
    has_tool_manifest,
  }
}

///|
pub async fn render_app_tool_book_status(
  book_id? : String = default_app_tool_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let status = inspect_app_tool_book(
    book_id~,
    workspace_root~,
    book_catalog_path~,
    standing_goal_path~,
  )
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
fn app_tool_book_resolved_workspace_root(
  book_id : String,
  workspace_root : String,
) -> String {
  if workspace_root.is_empty() {
    default_app_tool_book_workspace_root(book_id~)
  } else {
    workspace_root
  }
}

///|
async fn missing_app_tool_book_required_paths(
  workspace_root : String,
) -> Array[String] {
  workspace_missing_relative_paths(
    workspace_root,
    app_tool_book_required_paths(),
  )
}
