///|
pub async fn read_review_result_text(
  result_dir : String,
  book_id : String,
) -> String {
  let path = @book_quality.review_result_path(result_dir, book_id)
  if !@fs.exists(path) {
    return ""
  }
  @fs.read_file(path).text()
}

///|
pub async fn score_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> @book_quality.BookQualityScore {
  @book_quality.score_book_with_observations(
    entry,
    content=score_book_content_observation(entry, review_result_dir),
    structural=score_book_structural_observation(entry),
  )
}

///|
async fn score_book_content_observation(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> @book_quality.BookQualityContentObservation {
  let root = @moonbook.workspace_root(entry)
  {
    semantic_review_text: read_review_result_text(review_result_dir, entry.id),
    research_deep_report_word_count: @support.count_english_word_tokens(
      @support.read_text_or_empty(
        @book_quality.workspace_path(root, "raw/bootstrap/deep-report.md"),
      ),
    ),
    course_index_text: @support.read_text_or_empty(
      @book_quality.workspace_path(root, @book_quality.wiki_index_path()),
    ),
    cookbook_audit_exists: @fs.exists(".moontown/book-quality/audit.json"),
  }
}

///|
async fn score_book_structural_observation(
  entry : @moonbook.BookCatalogEntry,
) -> @book_quality.BookQualityStructuralObservation {
  let root = @moonbook.workspace_root(entry)
  let existing_relative_paths : Array[String] = []
  for relative in @book_quality.structural_required_relative_paths(entry) {
    if @fs.exists(@book_quality.workspace_path(root, relative)) {
      existing_relative_paths.push(relative)
    }
  }
  {
    workspace_exists: @fs.exists(root),
    wiki_index_exists: @fs.exists(
      @book_quality.workspace_path(root, @book_quality.wiki_index_path()),
    ),
    projection_state_exists: @fs.exists(
      @book_quality.workspace_path(root, @book_quality.projection_state_path()),
    ),
    existing_relative_paths,
    civic_latest_result_exists: score_book_civic_latest_result_exists(entry),
  }
}

///|
async fn score_book_civic_latest_result_exists(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      @fs.exists(
        @civic.civic_service_result_path(
          service,
          root=@moonbook.workspace_root(entry),
        ),
      )
    None => false
  }
}

///|
pub async fn write_accepted_review_result(
  result_dir : String,
  run : @book_quality.BookQualityReviewRun,
  content : String,
) -> Unit {
  @support.write_text_file(
    @book_quality.review_result_path(result_dir, run.book_id),
    content,
  )
}
