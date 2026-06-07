///|
priv struct BookQualityScoreDraft {
  root : String
  strengths : Array[String]
  gaps : Array[String]
  base_score : Int
}

///|
async fn new_book_quality_score_draft(
  entry : @moonbook.BookCatalogEntry,
) -> BookQualityScoreDraft {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  {
    root,
    strengths,
    gaps,
    base_score: base_workspace_score(root, strengths, gaps),
  }
}

///|
async fn finalize_score_draft(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  draft : BookQualityScoreDraft,
  raw_score : Int,
  review_result_dir : String,
) -> BookQualityScore {
  finalize_score(
    entry,
    book_type,
    draft.root,
    raw_score,
    draft.strengths,
    draft.gaps,
    review_result_dir,
  )
}
