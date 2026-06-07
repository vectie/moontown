///|
test "book quality repair review contract parses AI fields and defaults safely" {
  let score = book_quality_score_fixture(
    "research-robotics",
    book_quality_research_type(),
    "/tmp/research-robotics",
  )
  let parsed = book_quality_repair_review_contract(
    [
      "ai_quality_score: 63", "ai_quality_grade: usable", "repair_owner: moonbook",
      "next_repair_task: build an evidence matrix",
    ].join("\n"),
    score,
  )
  assert_eq(parsed.semantic_grade, "usable")
  assert_eq(parsed.repair_owner, "moonbook")
  assert_eq(parsed.next_repair_task, "build an evidence matrix")
  let fallback = book_quality_repair_review_contract(
    "ai_quality_score: 63\n", score,
  )
  assert_eq(fallback.semantic_grade, score.semantic_grade)
  assert_eq(fallback.repair_owner, "mixed")
  assert_eq(fallback.next_repair_task, score.next_action)
}

///|
test "book quality repair bridge item uses parsed contract fields" {
  let score = book_quality_score_fixture(
    "research-robotics",
    book_quality_research_type(),
    "/tmp/research-robotics",
  )
  let item = book_quality_repair_bridge_item(
    score,
    "/tmp/result.md",
    [
      "ai_quality_score: 71", "ai_quality_grade: usable", "repair_owner: moonbook",
      "next_repair_task: improve source synthesis",
    ].join("\n"),
    71,
  )
  assert_eq(item.book_id, "research-robotics")
  assert_eq(item.semantic_grade, "usable")
  assert_eq(item.repair_owner, "moonbook")
  assert_eq(item.next_repair_task, "improve source synthesis")
  assert_eq(item.review_result_path, "/tmp/result.md")
  assert_eq(
    item.book_review_path,
    "/tmp/research-robotics/wiki/reviews/book-quality-repair.md",
  )
}
