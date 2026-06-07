///|
async fn score_general_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let score = draft.base_score +
    path_score(
      draft.root,
      book_quality_wiki_index_path(),
      20,
      draft.strengths,
      draft.gaps,
    ) +
    path_score(
      draft.root,
      book_quality_projection_state_path(),
      15,
      draft.strengths,
      draft.gaps,
    )
  finalize_score_draft(
    entry,
    book_quality_general_type(),
    draft,
    score,
    review_result_dir,
  )
}
