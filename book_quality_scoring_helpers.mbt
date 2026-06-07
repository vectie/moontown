///|
async fn finalize_score(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  root : String,
  raw_score : Int,
  strengths : Array[String],
  gaps : Array[String],
  review_result_dir : String,
) -> BookQualityScore {
  let structural = assess_structural_quality(raw_score, gaps)
  let semantic_result_text = read_ai_quality_result_text(
    entry.id,
    review_result_dir,
  )
  let semantic_score = parse_ai_quality_score(semantic_result_text)
  let semantic = semantic_quality_assessment(semantic_score)
  {
    book_id: entry.id,
    title: entry.name,
    book_type,
    workspace_root: root,
    structural_score: structural.score,
    structural_grade: structural.grade,
    semantic_score: semantic.score,
    semantic_grade: semantic.grade,
    quality_status: semantic.status,
    score: structural.score,
    grade: structural.grade,
    ready: structural.ready_without_semantic && semantic.allows_ready,
    strengths,
    gaps,
    next_action: next_book_quality_action(
      book_type,
      gaps,
      structural.score,
      semantic.score,
      semantic_repair_task=book_quality_semantic_repair_task(
        semantic_result_text,
      ),
    ),
  }
}
