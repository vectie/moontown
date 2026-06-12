///|
async fn load_pdf_evidence_watch_install_spec(
  config_path : String,
) -> PdfEvidenceWatchInstallSpec? {
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
  spec : PdfEvidenceWatchInstallSpec,
  base_dir : String,
) -> String {
  resolve_book_template_config_text_override(
    spec.analysis_method,
    spec.analysis_method_path,
    base_dir,
  )
}
