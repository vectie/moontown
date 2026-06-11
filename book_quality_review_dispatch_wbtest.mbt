///|
async test "book quality review candidate selection favors the weakest pending score" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-dispatch-candidate-wbtest",
  )
  let result_dir = "\{root}/results"
  let weaker = {
    ..book_quality_score_fixture(
      "weak-book",
      @book_quality.research_type(),
      "/tmp/weak-book",
    ),
    structural_score: 41,
  }
  let stronger = {
    ..book_quality_score_fixture(
      "strong-book",
      @book_quality.research_type(),
      "/tmp/strong-book",
    ),
    structural_score: 88,
  }
  let equal = { ..stronger, book_id: "equal-book" }
  let audit = @book_quality.audit_from_scores("/tmp/catalog.json", [
    stronger, weaker, equal,
  ])
  let candidate = @book_quality.first_pending_review_score(audit, result_dir)
  assert_true(candidate is Some(_))
  assert_eq(candidate.unwrap().book_id, "weak-book")
  write_text_file(
    @book_quality.review_result_path(result_dir, "weak-book"),
    "ai_quality_score: 82\n",
  )
  let next = @book_quality.first_pending_review_score(audit, result_dir)
  assert_true(next is Some(_))
  assert_eq(next.unwrap().book_id, "strong-book")
}

///|
test "book quality external review packet carries shared MoonClaw policy" {
  let packet = @book_quality.BookQualityReviewPacket::{
    book_id: "coding",
    book_type: @book_quality.operational_type(),
    policy: @policy.operational(),
    workspace_root: "/tmp/coding",
    structural_score: 100,
    review_skill_path: "/tmp/review/BOOK_QUALITY_REVIEW_SKILL.md",
    context_pages: ["wiki/index.md"],
    prompt: "Review the book.",
    output_contract: @book_quality.review_output_contract(),
  }
  let external = @book_quality.review_external_packet(packet, "/tmp/results")
  let metadata = external.metadata.stringify()
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
  assert_true(metadata.contains("\"book_policy\":{"))
  assert_true(metadata.contains("\"operational-keeper\""))
  assert_true(metadata.contains("\"profile_metadata\":{"))
  assert_true(metadata.contains("\"step_metadata\":{"))
  assert_true(metadata.contains("\"result_path\":\"/tmp/results/coding.md\""))
}

///|
async test "book quality review packet helpers expose paths and result state" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-packet-helper-wbtest",
  )
  let result_dir = "\{root}/results"
  assert_eq(
    @book_quality.review_skill_path("\{root}/review"),
    "\{root}/review/BOOK_QUALITY_REVIEW_SKILL.md",
  )
  assert_false(
    @fs.exists(@book_quality.review_result_path(result_dir, "course-example")),
  )
  write_text_file(
    @book_quality.review_result_path(result_dir, "course-example"),
    "ai_quality_score: 88\n",
  )
  assert_true(
    @fs.exists(@book_quality.review_result_path(result_dir, "course-example")),
  )
}

///|
test "book quality dispatch messages stay stable" {
  assert_eq(
    @book_quality.active_review_dispatch_message(2),
    "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=2",
  )
  assert_eq(
    @book_quality.no_pending_review_dispatch_message("/tmp/results"),
    "No pending AI semantic book-quality review remains. Results are stored under /tmp/results.",
  )
}
