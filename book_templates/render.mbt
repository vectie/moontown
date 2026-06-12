///|
pub async fn render_book_template_registry(
  registry_path? : String = default_registry_path(),
) -> String {
  let registry = inspect_registry(registry_path~)
  render_registry_markdown(registry)
}

///|
pub async fn render_book_template_request_status(
  request_path? : String = request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
) -> String {
  let status = inspect_book_template_request_status(request_path~)
  let ledger = load_request_ledger(request_path)
  render_request_status_markdown(status, ledger)
}
