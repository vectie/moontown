///|
pub fn repair_review_page_markdown(
  item : BookQualityRepairBridgeItem,
  result_text : String,
) -> String {
  [
    "# Book Quality Repair Queue",
    "",
    "This page is generated from MoonTown's semantic book-quality review. It is a repair queue, not accepted domain evidence.",
    "",
    "## Current Repair",
    "",
    "- Book: `\{item.book_id}`",
    @policy.book_type_bullet(item.book_type),
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
  ].join("\n")
}
