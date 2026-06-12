///|
pub async fn install_book_template_config(
  template_id : String,
  config_path : String,
  registry_path? : String = @book_templates.default_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  @book_templates.install_book_template_config(
    template_id,
    config_path,
    registry_path~,
    book_catalog_path~,
    standing_goal_path~,
  )
}

///|
pub async fn render_book_template_registry(
  registry_path? : String = @book_templates.default_registry_path(),
) -> String {
  @book_templates.render_book_template_registry(registry_path~)
}

///|
pub async fn process_book_template_requests(
  request_path? : String = @book_templates.request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
  registry_path? : String = @book_templates.default_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  tick? : Int = 0,
) -> String {
  @book_templates.process_book_template_requests(
    request_path~,
    registry_path~,
    book_catalog_path~,
    standing_goal_path~,
    tick~,
  )
}

///|
pub async fn inspect_book_template_request_status(
  request_path? : String = @book_templates.request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
) -> @book_templates.BookTemplateRequestStatus {
  @book_templates.inspect_book_template_request_status(request_path~)
}

///|
pub async fn render_book_template_request_status(
  request_path? : String = @book_templates.request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
) -> String {
  @book_templates.render_book_template_request_status(request_path~)
}
