///|
pub async fn inspect_app_tool_book(
  book_id? : String = default_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> AppToolBookStatus {
  let root = resolved_workspace_root(book_id, workspace_root)
  let missing = missing_required_paths(root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let has_catalog_entry = @moonbook.entry_for_book_id(catalog, book_id)
    is Some(_)
  let goal_id = standing_goal_id(book_id)
  let has_standing_goal = standing_goal_in(goals, goal_id)
  let standing_goal_enabled = standing_goal_enabled_in(goals, goal_id)
  let has_tool_manifest = @fs.exists("\{root}/tool-manifest.json")
  status(
    book_id,
    root,
    missing,
    has_catalog_entry~,
    has_standing_goal~,
    standing_goal_enabled~,
    has_tool_manifest~,
  )
}

///|
pub async fn render_app_tool_book_status(
  book_id? : String = default_book_id(),
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
  status_markdown(status)
}
