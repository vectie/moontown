///|
async test "book quality repair bridge candidate only accepts weak semantic review" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-bridge-candidate-wbtest",
  )
  let result_dir = "\{root}/book-quality/ai-review-results"
  let score = @book_quality.BookQualityScore::{
    book_id: "research-robotics",
    title: "Robotics",
    book_type: @book_quality.research_type(),
    workspace_root: "\{root}/books/research-robotics",
    structural_score: 77,
    structural_grade: "usable",
    semantic_score: None,
    semantic_grade: "pending-ai-review",
    quality_status: "pending-ai-review",
    score: 77,
    grade: "usable",
    ready: false,
    strengths: [],
    gaps: [],
    next_action: "fallback repair",
  }
  assert_true(book_quality_repair_bridge_candidate(score, result_dir) is None)
  write_book_quality_ai_review_result_fixture(
    result_dir,
    score.book_id,
    @book_quality.semantic_ready_threshold(),
    grade="usable",
    next_repair_task="should not queue",
  )
  assert_true(book_quality_repair_bridge_candidate(score, result_dir) is None)
  write_book_quality_ai_review_result_fixture(
    result_dir,
    score.book_id,
    @book_quality.semantic_ready_threshold() - 1,
    grade="usable",
  )
  match book_quality_repair_bridge_candidate(score, result_dir) {
    Some(candidate) => {
      assert_eq(candidate.item.book_id, "research-robotics")
      assert_eq(
        candidate.item.semantic_score,
        @book_quality.semantic_ready_threshold() - 1,
      )
      assert_eq(candidate.item.repair_owner, "moonbook")
      assert_eq(candidate.item.next_repair_task, "improve source synthesis")
      assert_true(candidate.result_text.contains("ai_quality_score"))
    }
    None => fail("expected weak semantic review repair candidate")
  }
}

///|
async test "book quality repair bridge applies only repairable weak candidates" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-bridge-apply-candidates-wbtest",
  )
  let result_dir = "\{root}/results"
  let repairable = book_quality_score_fixture(
    "research-robotics",
    @book_quality.research_type(),
    "\{root}/books/research-robotics",
  )
  let archived = book_quality_score_fixture(
    "archived-research",
    @book_quality.research_type(),
    "\{root}/books/archived-research",
  )
  for book_id in ["research-robotics", "archived-research"] {
    write_book_quality_ai_review_result_fixture(result_dir, book_id, 44)
  }
  let goals : Array[@core.StandingGoal] = []
  let repaired = apply_book_quality_repair_bridge_candidates(
    [repairable, archived],
    ["research-robotics"],
    result_dir,
    goals,
    12,
  )
  assert_eq(repaired.length(), 1)
  assert_eq(repaired[0].book_id, "research-robotics")
  assert_true(
    @fs.exists(
      "\{root}/books/research-robotics/wiki/reviews/book-quality-repair.md",
    ),
  )
  assert_false(
    @fs.exists(
      "\{root}/books/archived-research/wiki/reviews/book-quality-repair.md",
    ),
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, @book_quality.repair_goal_id("research-robotics"))
  assert_eq(goals[0].next_due_tick, 13)
}
