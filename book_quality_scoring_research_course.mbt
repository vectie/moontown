///|
async fn score_research_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    research_book_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  let words = count_english_word_tokens(
    read_text_or_empty(
      book_quality_workspace_path(draft.root, "raw/bootstrap/deep-report.md"),
    ),
  )
  if words >= 12000 {
    score += 18
    draft.strengths.push("deep report reaches 12k+ words")
  } else if words >= 8000 {
    score += 12
    draft.gaps.push("deep report below world-class 12k word target")
  } else if words >= 2000 {
    score += 6
    draft.gaps.push("deep report is useful but too short for deep research")
  } else {
    draft.gaps.push("deep report is missing or shallow")
  }
  finalize_score_draft(
    entry,
    book_quality_research_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
fn research_book_required_paths() -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("raw/bootstrap/research-question.md", 6),
    book_quality_required_path("raw/bootstrap/search-log.md", 8),
    book_quality_required_path("raw/bootstrap/source-screen.md", 8),
    book_quality_required_path("raw/bootstrap/evidence-matrix.md", 10),
    book_quality_required_path("raw/bootstrap/deep-report.md", 12),
    book_quality_required_path("raw/bootstrap/marketing-brief.md", 5),
    book_quality_required_path(book_quality_wiki_index_path(), 7),
    book_quality_required_path(book_quality_generated_site_path(), 6),
  ]
}

///|
async fn score_course_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    course_book_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  let index = read_text_or_empty(
    book_quality_workspace_path(draft.root, book_quality_wiki_index_path()),
  ).to_lower()
  if index.contains("## research report") || entry.id.has_prefix("research-") {
    draft.gaps.push("course still looks research-shaped in id or index")
  } else if index.contains("course book") ||
    index.contains("type: `course-book`") {
    score += 8
    draft.strengths.push("course identity is explicit")
  }
  finalize_score_draft(
    entry,
    book_quality_course_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
fn course_book_required_paths() -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("raw/bootstrap/COURSE_CONTRACT.md", 12),
    book_quality_required_path("raw/bootstrap/course-outline.md", 10),
    book_quality_required_path("raw/bootstrap/source-material.md", 4),
    book_quality_required_path("wiki/course/beginner-course.md", 16),
    book_quality_required_path("wiki/course/exercises.md", 10),
    book_quality_required_path("wiki/course/progress-rubric.md", 8),
    book_quality_required_path("skills/course-builder/SKILL.md", 12),
    book_quality_required_path(book_quality_generated_site_path(), 6),
  ]
}
