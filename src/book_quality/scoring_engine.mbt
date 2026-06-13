///|
pub fn review_result_dir_for_snapshot(snapshot_path : String) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/book-quality/ai-review-results"
}

///|
pub async fn score_book_with_review_text(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let kind = score_book_type(entry)
  match kind {
    type_ if type_ == @policy.research_type() =>
      score_research_book(entry, semantic_review_text)
    type_ if type_ == @policy.course_type() =>
      score_course_book(entry, semantic_review_text)
    type_ if type_ == @policy.planbook_type() =>
      score_planbook(entry, semantic_review_text)
    type_ if type_ == @policy.cookbook_type() =>
      score_cookbook(entry, semantic_review_text)
    type_ if type_ == @policy.civic_type() =>
      score_civic_book(entry, semantic_review_text)
    type_ if type_ == @policy.operational_type() =>
      score_operational_book(entry, semantic_review_text)
    _ => score_general_book(entry, semantic_review_text)
  }
}

///|
fn score_book_type(entry : @moonbook.BookCatalogEntry) -> String {
  @policy.catalog_entry_type(entry.id, entry.name, entry.tags)
}

///|
async fn score_research_book(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    research_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  let words = @support.count_english_word_tokens(
    @support.read_text_or_empty(
      workspace_path(draft.root, "raw/bootstrap/deep-report.md"),
    ),
  )
  score += apply_score_signal(
    research_deep_report_word_assessment(words),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.research_type(),
    draft,
    score,
    semantic_review_text,
  )
}

///|
async fn score_course_book(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    course_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  let index = @support.read_text_or_empty(
    workspace_path(draft.root, wiki_index_path()),
  )
  score += apply_score_signal(
    course_identity_assessment(entry.id, index),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.course_type(),
    draft,
    score,
    semantic_review_text,
  )
}

///|
async fn score_planbook(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    planbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.planbook_type(),
    draft,
    score,
    semantic_review_text,
  )
}

///|
async fn score_cookbook(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    cookbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  score += apply_score_signal(
    cookbook_audit_link_assessment(
      @fs.exists(".moontown/book-quality/audit.json"),
    ),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.cookbook_type(),
    draft,
    score,
    semantic_review_text,
  )
}

///|
async fn score_operational_book(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    operational_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.operational_type(),
    draft,
    score,
    semantic_review_text,
  )
}

///|
async fn score_civic_book(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    civic_base_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      score += score_civic_service_definition(
        draft.root,
        service,
        draft.strengths,
        draft.gaps,
      )
    None => draft.gaps.push("no civic service definition matched this book")
  }
  finalize_score_draft(
    entry,
    @policy.civic_type(),
    draft,
    score,
    semantic_review_text,
  )
}

///|
async fn score_general_book(
  entry : @moonbook.BookCatalogEntry,
  semantic_review_text : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let score = draft.base_score +
    path_score(draft.root, wiki_index_path(), 20, draft.strengths, draft.gaps) +
    path_score(
      draft.root,
      projection_state_path(),
      15,
      draft.strengths,
      draft.gaps,
    )
  finalize_score_draft(
    entry,
    @policy.general_type(),
    draft,
    score,
    semantic_review_text,
  )
}
