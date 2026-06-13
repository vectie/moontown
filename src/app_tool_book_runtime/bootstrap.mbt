///|
pub async fn bootstrap_app_tool_book(
  book_id? : String = @app_tool_book.default_book_id(),
  title? : String = "Data Watch ToolBook",
  purpose? : String = @app_tool_book.default_purpose(),
  websites? : Array[String] = [],
  analysis_method? : String = "",
  tool_spec? : String = "",
  civic_building_id? : String = "data-watch-lab",
  cadence_ticks? : Int = 60,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  workspace_root? : String = "",
  template_root? : String = @app_tool_book.template_root(),
) -> String {
  let root = @app_tool_book.resolved_workspace_root(book_id, workspace_root)
  let entry = @app_tool_book.catalog_entry(book_id, title, purpose, root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_single_book(catalog, entry),
  )
  write_app_tool_book_workspace(
    entry, title, purpose, websites, analysis_method, tool_spec, civic_building_id,
    cadence_ticks, template_root,
  )
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let goal = @app_tool_book.standing_goal(
    book_id, title, purpose, websites, civic_building_id, cadence_ticks,
  )
  @storage.save_standing_goals_file(
    standing_goal_path,
    @app_tool_book.upsert_standing_goal(goals, goal),
  )
  let status = inspect_app_tool_book(
    book_id~,
    workspace_root=root,
    book_catalog_path~,
    standing_goal_path~,
  )
  [
    install_success_marker(),
    @app_tool_book.bootstrap_summary(
      book_id,
      root,
      book_catalog_path,
      goal.id,
      standing_goal_path,
      civic_building_id,
      websites.length(),
      status,
    ),
  ].join("\n")
}

///|
pub async fn install_app_tool_book_config(
  config_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  template_root? : String = @app_tool_book.template_root(),
) -> String {
  match load_app_tool_book_install_spec(config_path) {
    Some(spec) =>
      install_loaded_app_tool_book_spec(
        spec, config_path, book_catalog_path, standing_goal_path, template_root,
      )
    None => "Could not load App ToolBook config: \{config_path}"
  }
}

///|
async fn install_loaded_app_tool_book_spec(
  spec : @app_tool_book.AppToolBookInstallSpec,
  config_path : String,
  book_catalog_path : String,
  standing_goal_path : String,
  template_root : String,
) -> String {
  let base_dir = @path.Path::dirname(config_path).to_string()
  let analysis_method = resolve_app_tool_book_text_override(
    spec.analysis_method,
    spec.analysis_method_path,
    base_dir,
  )
  let tool_spec = resolve_app_tool_book_text_override(
    spec.tool_spec,
    spec.tool_spec_path,
    base_dir,
  )
  let workspace_root = resolve_book_template_config_workspace_root(
    base_dir,
    spec.workspace_root,
    @moonbook.default_workspace_root(spec.book_id),
  )
  let summary = bootstrap_app_tool_book(
    book_id=spec.book_id,
    title=spec.title,
    purpose=spec.purpose,
    websites=spec.websites,
    analysis_method~,
    tool_spec~,
    civic_building_id=spec.civic_building_id,
    cadence_ticks=spec.cadence_ticks,
    book_catalog_path~,
    standing_goal_path~,
    workspace_root~,
    template_root~,
  )
  @app_tool_book.install_config_summary(config_path, summary)
}
