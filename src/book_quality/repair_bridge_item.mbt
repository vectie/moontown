///|
pub fn repair_bridge_item(
  score : BookQualityScore,
  result_path : String,
  result_text : String,
  semantic_score : Int,
  generated_at_ms~ : UInt64,
) -> BookQualityRepairBridgeItem {
  let contract = repair_review_contract(result_text, score)
  {
    book_id: score.book_id,
    book_type: score.book_type,
    workspace_root: score.workspace_root,
    semantic_grade: contract.semantic_grade,
    repair_owner: contract.repair_owner,
    next_repair_task: contract.next_repair_task,
    review_result_path: result_path,
    book_review_path: "\{score.workspace_root}/wiki/reviews/book-quality-repair.md",
    standing_goal_id: repair_goal_id(score.book_id),
    status: review_run_queued_status(),
    generated_at_ms,
    semantic_score,
  }
}

///|
pub fn repair_bridge_item_from_review_text(
  score : BookQualityScore,
  result_path : String,
  result_text : String,
  generated_at_ms~ : UInt64,
) -> BookQualityRepairBridgeItem? {
  match parse_ai_quality_score(result_text) {
    Some(value) if semantic_review_requires_repair(Some(value)) =>
      Some(
        repair_bridge_item(
          score,
          result_path,
          result_text,
          value,
          generated_at_ms~,
        ),
      )
    _ => None
  }
}
