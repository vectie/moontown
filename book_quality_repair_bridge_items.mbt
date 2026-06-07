///|
fn book_quality_repair_bridge_item(
  score : BookQualityScore,
  result_path : String,
  result_text : String,
  semantic_score : Int,
) -> BookQualityRepairBridgeItem {
  let contract = book_quality_repair_review_contract(result_text, score)
  {
    book_id: score.book_id,
    book_type: score.book_type,
    workspace_root: score.workspace_root,
    semantic_grade: contract.semantic_grade,
    repair_owner: contract.repair_owner,
    next_repair_task: contract.next_repair_task,
    review_result_path: result_path,
    book_review_path: "\{score.workspace_root}/wiki/reviews/book-quality-repair.md",
    standing_goal_id: book_quality_repair_goal_id(score.book_id),
    status: book_quality_review_run_queued_status(),
    generated_at_ms: @env.now(),
    semantic_score,
  }
}

///|
priv struct BookQualityRepairReviewContract {
  semantic_grade : String
  repair_owner : String
  next_repair_task : String
}

///|
fn book_quality_repair_review_contract(
  result_text : String,
  score : BookQualityScore,
) -> BookQualityRepairReviewContract {
  {
    semantic_grade: book_quality_contract_field(result_text, "ai_quality_grade").unwrap_or(
      score.semantic_grade,
    ),
    repair_owner: book_quality_contract_field(result_text, "repair_owner").unwrap_or(
      "mixed",
    ),
    next_repair_task: book_quality_contract_field(
      result_text, "next_repair_task",
    ).unwrap_or(score.next_action),
  }
}

///|
async fn write_book_quality_repair_review_page(
  item : BookQualityRepairBridgeItem,
  result_text : String,
) -> Unit {
  write_text_file(
    item.book_review_path,
    [
      "# Book Quality Repair Queue",
      "",
      "This page is generated from Moontown's semantic book-quality review. It is a repair queue, not accepted domain evidence.",
      "",
      "## Current Repair",
      "",
      "- Book: `\{item.book_id}`",
      "- Type: `\{item.book_type}`",
      "- AI quality: `\{item.semantic_score}` / `\{item.semantic_grade}`",
      "- Repair owner: `\{item.repair_owner}`",
      "- Standing repair goal: `\{item.standing_goal_id}`",
      "- Status: `\{item.status}`",
      "",
      "## Next Repair Task",
      "",
      item.next_repair_task,
      "",
      "## Review Contract",
      "",
      "```md",
      result_text.trim().to_owned(),
      "```",
      "",
      "## Accounting Rule",
      "",
      "Do not mark this repair as accepted progress until the owning MoonBook or civic protocol has updated durable domain/service artifacts and a later semantic review no longer reports this gap.",
    ].join("\n"),
  )
}

///|
fn book_quality_contract_field(text : String, key : String) -> String? {
  let needle = "\{key.to_lower()}:"
  for raw in text.split("\n") {
    let line = raw.trim()
    let lower = line.to_lower()
    if lower.has_prefix(needle) {
      return Some(line[needle.length():].trim().to_owned())
    }
  }
  None
}
