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
  let ledger = load_review_run_ledger_file(run_path)
  @book_quality.review_status_markdown_from_observations(
    run_path,
    result_dir,
    active_book_ids~,
    ledger,
    book_quality_review_run_observations(ledger.runs, result_dir),
    @env.now(),
  )
}

///|
async fn book_quality_review_run_observations(
  runs : Array[@book_quality.BookQualityReviewRun],
  result_dir : String,
) -> Array[@book_quality.BookQualityReviewRunObservation] {
  let observations : Array[@book_quality.BookQualityReviewRunObservation] = []
  for run in runs {
    observations.push(@book_quality.BookQualityReviewRunObservation::{
      run,
      has_result: @fs.exists(
        @book_quality.review_result_path(result_dir, run.book_id),
      ) ||
      @fs.exists(run.result_path),
      process_alive: false,
    })
  }
  observations
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
