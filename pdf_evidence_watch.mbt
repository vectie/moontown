///|
pub async fn bootstrap_pdf_evidence_watch_book(
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  title? : String = "PDF Evidence Watch",
  purpose? : String = @pdf_evidence_watch.default_pdf_evidence_watch_purpose(),
  websites? : Array[String] = [],
  analysis_method? : String = "",
  cadence_ticks? : Int = 60,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  workspace_root? : String = "",
  template_root? : String = @pdf_evidence_watch.default_pdf_evidence_watch_template_root(),
) -> String {
  @pdf_evidence_watch.bootstrap_pdf_evidence_watch_book(
    book_id~,
    title~,
    purpose~,
    websites~,
    analysis_method~,
    cadence_ticks~,
    book_catalog_path~,
    standing_goal_path~,
    workspace_root~,
    template_root~,
  )
}

///|
pub async fn install_pdf_evidence_watch_book_config(
  config_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  template_root? : String = @pdf_evidence_watch.default_pdf_evidence_watch_template_root(),
) -> String {
  @pdf_evidence_watch.install_pdf_evidence_watch_book_config(
    config_path,
    book_catalog_path~,
    standing_goal_path~,
    template_root~,
  )
}

///|
pub async fn inspect_pdf_evidence_watch_book(
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> @pdf_evidence_watch.PdfEvidenceWatchBookStatus {
  @pdf_evidence_watch.inspect_pdf_evidence_watch_book(
    book_id~,
    workspace_root~,
    book_catalog_path~,
    standing_goal_path~,
  )
}

///|
pub async fn render_pdf_evidence_watch_book_status(
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  @pdf_evidence_watch.render_pdf_evidence_watch_book_status(
    book_id~,
    workspace_root~,
    book_catalog_path~,
    standing_goal_path~,
  )
}

///|
pub type PdfEvidenceWatchInstallSpec = @pdf_evidence_watch.PdfEvidenceWatchInstallSpec

///|
pub type PdfEvidenceWatchBookStatus = @pdf_evidence_watch.PdfEvidenceWatchBookStatus
