///|
pub async fn install_pdf_evidence_watch_book_config(
  config_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  template_root? : String = @pdf_evidence_watch.default_pdf_evidence_watch_template_root(),
) -> String {
  match load_pdf_evidence_watch_install_spec(config_path) {
    Some(spec) =>
      install_pdf_evidence_watch_spec(
        config_path, spec, book_catalog_path, standing_goal_path, template_root,
      )
    None => "Could not load PDF Evidence Watch config: \{config_path}"
  }
}

///|
async fn install_pdf_evidence_watch_spec(
  config_path : String,
  spec : @pdf_evidence_watch.PdfEvidenceWatchInstallSpec,
  book_catalog_path : String,
  standing_goal_path : String,
  template_root : String,
) -> String {
  let base_dir = @path.Path::dirname(config_path).to_string()
  let analysis_method = resolve_pdf_evidence_watch_analysis_method(
    spec, base_dir,
  )
  let workspace_root = resolve_book_template_config_workspace_root(
    base_dir,
    spec.workspace_root,
    @pdf_evidence_watch.default_pdf_evidence_watch_workspace_root(
      book_id=spec.book_id,
    ),
  )
  let summary = bootstrap_pdf_evidence_watch_book(
    book_id=spec.book_id,
    title=spec.title,
    purpose=spec.purpose,
    websites=spec.websites,
    analysis_method~,
    cadence_ticks=spec.cadence_ticks,
    book_catalog_path~,
    standing_goal_path~,
    workspace_root~,
    template_root~,
  )
  "Installed PDF Evidence Watch config `\{config_path}`.\n\{summary}"
}

///|
async fn load_pdf_evidence_watch_install_spec(
  config_path : String,
) -> @pdf_evidence_watch.PdfEvidenceWatchInstallSpec? {
  let parsed = match read_optional_json_file(config_path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn resolve_pdf_evidence_watch_analysis_method(
  spec : @pdf_evidence_watch.PdfEvidenceWatchInstallSpec,
  base_dir : String,
) -> String {
  resolve_book_template_config_text_override(
    spec.analysis_method,
    spec.analysis_method_path,
    base_dir,
  )
}
