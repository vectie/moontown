///|
async fn load_app_tool_book_install_spec(
  config_path : String,
) -> @app_tool_book.AppToolBookInstallSpec? {
  let parsed = match read_optional_json_file(config_path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn resolve_app_tool_book_text_override(
  inline_text : String,
  path : String,
  base_dir : String,
) -> String {
  resolve_book_template_config_text_override(inline_text, path, base_dir)
}
