///|
async fn load_app_tool_book_install_spec(
  config_path : String,
) -> AppToolBookInstallSpec? {
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

///|
priv struct AppToolBookPathSpec {
  path : String
  copy_from_template : Bool
}

///|
fn app_tool_book_path_specs() -> Array[AppToolBookPathSpec] {
  [
    { path: "book.json", copy_from_template: false },
    { path: "tool-manifest.json", copy_from_template: false },
    {
      path: "raw/bootstrap/APP_TOOL_BOOK_CONTRACT.md",
      copy_from_template: true,
    },
    { path: "wiki/index.md", copy_from_template: true },
    { path: "wiki/methods/analysis-method.md", copy_from_template: true },
    { path: "wiki/tools/tool-spec.md", copy_from_template: true },
    { path: "wiki/reports/latest-analysis.md", copy_from_template: true },
    { path: "wiki/reviews/tool-review.md", copy_from_template: true },
    { path: "skills/tool-watch/SKILL.md", copy_from_template: true },
    { path: "skills/tool-build/SKILL.md", copy_from_template: true },
    { path: "schemas/tool-manifest.schema.md", copy_from_template: true },
    { path: "app/index.html", copy_from_template: false },
    { path: "app/tool.js", copy_from_template: true },
    { path: "app/styles.css", copy_from_template: true },
    { path: "book/site/generated/index.html", copy_from_template: false },
    { path: "book/site/generated/tool.html", copy_from_template: false },
  ]
}

///|
fn app_tool_book_required_paths() -> Array[String] {
  app_tool_book_path_specs().map(fn(spec) { spec.path })
}

///|
fn app_tool_book_template_copy_paths() -> Array[String] {
  app_tool_book_path_specs()
  .filter(fn(spec) { spec.copy_from_template })
  .map(fn(spec) { spec.path })
}
