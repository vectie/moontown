///|
fn resolve_book_template_config_relative_path(
  base_dir : String,
  path : String,
) -> String {
  if path.has_prefix("/") || base_dir == "." || base_dir == "" {
    path
  } else {
    "\{base_dir}/\{path}"
  }
}

///|
async fn resolve_book_template_config_text_override(
  inline_text : String,
  path : String,
  base_dir : String,
) -> String {
  if !inline_text.trim().is_empty() {
    return inline_text
  }
  if path.trim().is_empty() {
    return ""
  }
  read_text_or_empty(resolve_book_template_config_relative_path(base_dir, path))
}

///|
fn resolve_book_template_config_workspace_root(
  base_dir : String,
  configured_workspace_root : String,
  default_workspace_root : String,
) -> String {
  if configured_workspace_root.trim().is_empty() {
    default_workspace_root
  } else {
    resolve_book_template_config_relative_path(
      base_dir, configured_workspace_root,
    )
  }
}
