///|
fn book_quality_review_result_dir_for_snapshot(
  snapshot_path : String,
) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    default_book_quality_review_result_dir()
  } else {
    "\{base}/book-quality/ai-review-results"
  }
}

///|
async fn score_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let kind = book_quality_type(entry)
  match kind {
    type_ if type_ == book_quality_research_type() =>
      score_research_book(entry, review_result_dir)
    type_ if type_ == book_quality_course_type() =>
      score_course_book(entry, review_result_dir)
    type_ if type_ == book_quality_planbook_type() =>
      score_planbook(entry, review_result_dir)
    type_ if type_ == book_quality_cookbook_type() =>
      score_cookbook(entry, review_result_dir)
    type_ if type_ == book_quality_civic_type() =>
      score_civic_book(entry, review_result_dir)
    type_ if type_ == book_quality_operational_type() =>
      score_operational_book(entry, review_result_dir)
    _ => score_general_book(entry, review_result_dir)
  }
}

///|
fn book_quality_type(entry : @moonbook.BookCatalogEntry) -> String {
  if is_cookbook_quality_entry(entry) {
    return book_quality_cookbook_type()
  }
  if is_planbook_quality_entry(entry) {
    return book_quality_planbook_type()
  }
  if is_course_quality_entry(entry) {
    return book_quality_course_type()
  }
  if is_research_quality_entry(entry) {
    return book_quality_research_type()
  }
  if is_civic_quality_entry(entry) {
    return book_quality_civic_type()
  }
  if is_operational_quality_entry(entry) {
    return book_quality_operational_type()
  }
  book_quality_general_type()
}

///|
fn is_cookbook_quality_entry(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.tags.contains("cookbook") || entry.id.contains("cookbook")
}

///|
fn is_planbook_quality_entry(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.tags.contains("planbook") || entry.id.has_prefix("plan-")
}

///|
fn is_course_quality_entry(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.tags.contains("course") ||
  entry.id.has_prefix("course-") ||
  entry.name.to_lower().contains("course")
}

///|
fn is_research_quality_entry(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.tags.contains("research") ||
  entry.id.has_prefix("research-") ||
  entry.name.to_lower().contains("research")
}

///|
fn is_civic_quality_entry(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.tags.contains("civic-service") || entry.id.has_prefix("wenyu-")
}

///|
fn is_operational_quality_entry(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.id == "coding" ||
  entry.id == "finance" ||
  entry.tags.contains("operational")
}
