///|
pub fn default_pdf_evidence_watch_template_root() -> String {
  "templates/books/pdf-evidence-watch"
}

///|
pub fn default_pdf_evidence_watch_book_id() -> String {
  "research-pdf-evidence-watch"
}

///|
pub fn default_pdf_evidence_watch_workspace_root(
  book_id? : String = default_pdf_evidence_watch_book_id(),
) -> String {
  @moonbook.default_workspace_root(book_id)
}

///|
pub fn default_pdf_evidence_watch_purpose() -> String {
  "Standing MoonBook workspace for website-driven PDF discovery, download, extraction, method-specific analysis, durable findings, and operator notification when accepted new knowledge appears."
}
