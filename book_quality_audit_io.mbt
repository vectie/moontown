///|
async fn write_book_quality_audit_files(
  book_catalog_path : String,
  snapshot_path : String,
  audit_path : String,
) -> String {
  ignore(bootstrap_default_operational_books(book_catalog_path))
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  write_text_file(audit_path, audit.to_json().stringify(indent=2))
  let markdown_path = book_quality_markdown_path(audit_path)
  write_text_file(markdown_path, render_book_quality_audit(audit))
  "Wrote book management audit for \{audit.total} registered book(s) to \{audit_path} and \{markdown_path}; weakest_structural=\{audit.weakest_book_id}(\{audit.weakest_score}). Semantic quality scores require AI review results."
}
