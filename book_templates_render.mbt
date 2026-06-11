///|
pub async fn render_book_template_registry(
  registry_path? : String = @book_templates.default_registry_path(),
) -> String {
  let registry = @book_templates.inspect_registry(registry_path~)
  @book_templates.render_registry_markdown(registry)
}

///|
pub async fn render_book_template_request_status(
  request_path? : String = @book_templates.request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
) -> String {
  let status = inspect_book_template_request_status(request_path~)
  let ledger = @book_templates.load_request_ledger(request_path)
  @book_templates.render_request_status_markdown(status, ledger)
}
