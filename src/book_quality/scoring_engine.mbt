///|
pub fn review_result_dir_for_snapshot(snapshot_path : String) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/book-quality/ai-review-results"
}

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
  match kind {
    type_ if type_ == @policy.research_type() =>
      score_research_book(entry, content, structural)
    type_ if type_ == @policy.course_type() =>
      score_course_book(entry, content, structural)
    type_ if type_ == @policy.planbook_type() =>
      score_planbook(entry, content, structural)
    type_ if type_ == @policy.cookbook_type() =>
      score_cookbook(entry, content, structural)
    type_ if type_ == @policy.civic_type() =>
      score_civic_book(entry, content, structural)
    type_ if type_ == @policy.operational_type() =>
      score_operational_book(entry, content, structural)
    _ => score_general_book(entry, content, structural)
  }
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
fn score_research_book(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    research_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  score += apply_score_signal(
    research_deep_report_word_assessment(
      content.research_deep_report_word_count,
    ),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.research_type(),
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}

///|
fn score_course_book(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    course_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  score += apply_score_signal(
    course_identity_assessment(entry.id, content.course_index_text),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.course_type(),
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}

///|
fn score_planbook(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    planbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.planbook_type(),
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}

///|
fn score_cookbook(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    cookbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  score += apply_score_signal(
    cookbook_audit_link_assessment(content.cookbook_audit_exists),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.cookbook_type(),
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}

///|
fn score_operational_book(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    operational_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.operational_type(),
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}

///|
fn score_civic_book(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let mut score = draft.base_score
  score += required_paths_score(
    structural,
    civic_base_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      score += score_civic_service_definition(
        structural,
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
    structural,
    score,
    content.semantic_review_text,
  )
}

///|
fn score_general_book(
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
) -> BookQualityScore {
  let draft = new_score_draft(entry, structural)
  let score = draft.base_score +
    path_score(structural, wiki_index_path(), 20, draft.strengths, draft.gaps) +
    path_score(
      structural,
      projection_state_path(),
      15,
      draft.strengths,
      draft.gaps,
    )
  finalize_score_draft(
    entry,
    @policy.general_type(),
    draft,
    structural,
    score,
    content.semantic_review_text,
  )
}
