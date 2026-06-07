///|
pub async fn inspect_book_quality(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> BookQualityAudit {
  build_book_quality_audit(book_catalog_path, snapshot_path)
}

///|
pub async fn render_book_quality(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  render_book_quality_audit(
    inspect_book_quality(book_catalog_path~, snapshot_path~),
  )
}

///|
pub async fn write_book_quality_audit(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  audit_path? : String = default_book_quality_audit_path(),
) -> String {
  write_book_quality_audit_files(book_catalog_path, snapshot_path, audit_path)
}

///|
pub async fn write_book_quality_review_packets(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  review_dir? : String = default_book_quality_review_dir(),
) -> String {
  write_book_quality_review_packet_files(
    book_catalog_path, snapshot_path, review_dir,
  )
}

///|
pub async fn dispatch_next_book_quality_ai_review(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  review_dir? : String = default_book_quality_review_dir(),
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
  run_inline? : Bool = moontown_moonclaw_inline_enabled(),
) -> String {
  dispatch_next_book_quality_ai_review_run(
    book_catalog_path, snapshot_path, review_dir, result_dir, run_path, run_inline,
  )
}

///|
pub async fn bootstrap_registered_book_workspaces(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  bootstrap_canonical_registered_book_workspaces(book_catalog_path)
}
