///|
fn app_tool_book_catalog_entry(
  book_id : String,
  title : String,
  purpose : String,
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=book_id,
    name="MoonBook / App ToolBook / \{title}",
    purpose~,
    workspace_root~,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=[
      "toolbook", "appbook", "standing-watch", "generated-tool", "civic-building",
      "template:app-tool-book",
    ],
    skills=[
      "tool-watch", "tool-analysis", "tool-build", "tool-review", "notification-digest",
    ],
  )
}

///|
async fn write_app_tool_book_workspace(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
  analysis_method : String,
  tool_spec : String,
  civic_building_id : String,
  cadence_ticks : Int,
  template_root : String,
) -> Unit {
  let root = entry.workspace_root
  for path in app_tool_book_template_copy_paths() {
    copy_app_tool_book_template_file(template_root, root, path)
  }
  write_text_file(
    "\{root}/book.json",
    app_tool_book_config(
      entry, title, purpose, websites, civic_building_id, cadence_ticks,
    )
    .to_json()
    .stringify(indent=2),
  )
  write_text_file(
    "\{root}/tool-manifest.json",
    app_tool_book_manifest(entry, title, purpose, civic_building_id)
    .to_json()
    .stringify(indent=2),
  )
  write_text_file_if_missing("\{root}/raw/data/.keep", "")
  write_text_file_if_missing("\{root}/raw/analysis-runs/.keep", "")
  write_text_file_if_missing(
    "\{root}/wiki/history/standing-watch.md",
    app_tool_book_history_markdown(entry, title),
  )
  if !analysis_method.trim().is_empty() {
    write_text_file("\{root}/wiki/methods/analysis-method.md", analysis_method)
  }
  if !tool_spec.trim().is_empty() {
    write_text_file("\{root}/wiki/tools/tool-spec.md", tool_spec)
  }
  let app_html = app_tool_book_app_html(
    entry, title, purpose, civic_building_id,
  )
  write_text_file("\{root}/app/index.html", app_html)
  write_text_file("\{root}/book/site/generated/tool.html", app_html)
  write_text_file(
    "\{root}/book/site/generated/index.html",
    app_tool_book_site_index_html(entry, title, purpose, civic_building_id),
  )
  write_text_file(
    "\{root}/book/Home.html",
    app_tool_book_site_index_html(entry, title, purpose, civic_building_id),
  )
}

///|
async fn copy_app_tool_book_template_file(
  template_root : String,
  workspace_root : String,
  relative_path : String,
) -> Unit {
  let source = "\{template_root}/\{relative_path}"
  let content = read_text_or_empty(source)
  if content.trim().is_empty() {
    return
  }
  write_text_file("\{workspace_root}/\{relative_path}", content)
}
