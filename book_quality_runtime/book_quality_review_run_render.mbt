///|
pub async fn render_book_quality_ai_review_status(
  result_dir? : String = @book_quality.default_review_result_dir(),
  run_path? : String = @book_quality.default_review_run_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  ignore(reconcile_book_quality_ai_review_results(result_dir~, run_path~))
  let active_book_ids = book_quality_ai_review_active_book_ids(
    book_catalog_path, snapshot_path,
  )
  @book_quality.review_status_markdown_from_files(
    run_path,
    result_dir,
    active_book_ids~,
  )
}

///|
async fn book_quality_ai_review_active_book_ids(
  book_catalog_path : String,
  snapshot_path : String,
) -> Array[String] {
  let catalog = quality_catalog_with_runtime_books(
    @moonbook.load_or_create_catalog(path=book_catalog_path),
    snapshot_path,
  )
  catalog.map(fn(entry) { entry.id })
}
