///|
async fn write_pdf_evidence_watch_workspace(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  websites : Array[String],
  analysis_method : String,
  cadence_ticks : Int,
  template_root : String,
) -> Unit {
  let root = entry.workspace_root
  for path in @pdf_evidence_watch.pdf_evidence_watch_template_copy_paths() {
    copy_pdf_evidence_watch_template_file(template_root, root, path)
  }
  write_text_file(
    "\{root}/book.json",
    @pdf_evidence_watch.pdf_evidence_watch_config_json(
      entry, title, purpose, websites, cadence_ticks,
    ),
  )
  write_text_file_if_missing("\{root}/raw/pdfs/.keep", "")
  write_text_file_if_missing("\{root}/raw/extracted/.keep", "")
  write_text_file_if_missing("\{root}/raw/analysis-runs/.keep", "")
  write_text_file_if_missing(
    "\{root}/wiki/history/standing-watch.md",
    @pdf_evidence_watch.pdf_evidence_watch_history_markdown(entry, title),
  )
  if !analysis_method.trim().is_empty() {
    write_text_file("\{root}/wiki/methods/analysis-method.md", analysis_method)
  }
  let html = @pdf_evidence_watch.pdf_evidence_watch_generated_site_html(
    entry, title, purpose, websites,
  )
  write_text_file("\{root}/book/Home.html", html)
  write_text_file(
    @pdf_evidence_watch.pdf_evidence_watch_generated_site_workspace_path(root),
    html,
  )
}

///|
async fn copy_pdf_evidence_watch_template_file(
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
