///|
pub fn score_book_with_review_text(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  score_book_with_observation(
    entry,
    default_content_observation(semantic_review_text),
  )
}

///|
pub fn score_book_with_observation(
  entry : @moonbook.BookCatalogEntry,
  observation : BookQualityContentObservation,
) -> BookQualityScore {
  score_book_with_observations(
    entry,
    content=observation,
    structural=default_structural_observation(),
  )
}

///|
pub fn score_book_with_observations(
  entry : @moonbook.BookCatalogEntry,
  content~ : BookQualityContentObservation,
  structural~ : BookQualityStructuralObservation,
) -> BookQualityScore {
  let kind = score_book_type(entry)
  score_book_against_policy_type(entry, kind, content, structural)
}

///|
pub fn default_content_observation(
  semantic_review_text : String,
) -> BookQualityContentObservation {
  {
    semantic_review_text,
    research_deep_report_word_count: 0,
    course_index_text: "",
    cookbook_audit_exists: false,
  }
}

///|
pub fn default_structural_observation() -> BookQualityStructuralObservation {
  {
    workspace_exists: false,
    wiki_index_exists: false,
    projection_state_exists: false,
    existing_relative_paths: [],
    civic_latest_result_exists: false,
  }
}

///|
fn score_book_type(entry : @moonbook.BookCatalogEntry) -> String {
  @policy.catalog_entry_type(entry.id, entry.name, entry.tags)
}

///|
fn score_book_against_policy_type(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    required_paths_for_book_type(book_type),
    draft.strengths,
    draft.gaps,
  )
  score += book_type_signal_score(
    book_type,
    entry,
    content,
    structural,
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    book_type,
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}
