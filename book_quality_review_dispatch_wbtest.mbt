///|
test "book quality review candidate ordering favors lower structural score" {
  let weaker = {
    ..book_quality_score_fixture(
      "weak-book",
      book_quality_research_type(),
      "/tmp/weak-book",
    ),
    structural_score: 41,
  }
  let stronger = {
    ..book_quality_score_fixture(
      "strong-book",
      book_quality_research_type(),
      "/tmp/strong-book",
    ),
    structural_score: 88,
  }
  let equal = { ..stronger, book_id: "equal-book" }
  assert_true(book_quality_score_precedes_review_candidate(weaker, stronger))
  assert_false(book_quality_score_precedes_review_candidate(stronger, weaker))
  assert_false(book_quality_score_precedes_review_candidate(equal, stronger))
}

///|
test "book quality external review packet carries shared MoonClaw policy" {
  let packet = BookQualityReviewPacket::{
    book_id: "coding",
    book_type: book_quality_operational_type(),
    workspace_root: "/tmp/coding",
    structural_score: 100,
    review_skill_path: "/tmp/review/BOOK_QUALITY_REVIEW_SKILL.md",
    context_pages: ["wiki/index.md"],
    prompt: "Review the book.",
    output_contract: book_quality_review_output_contract(),
  }
  let external = book_quality_external_review_packet(packet, "/tmp/results")
  let metadata = external.metadata.stringify()
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
  assert_true(metadata.contains("\"profile_metadata\":{"))
  assert_true(metadata.contains("\"step_metadata\":{"))
  assert_true(metadata.contains("\"result_path\":\"/tmp/results/coding.md\""))
}

///|
test "book quality review run constructor centralizes common fields" {
  let run = book_quality_review_run(
    "book-run",
    "/tmp/packet.json",
    "/tmp/results",
    Some("proposal-run"),
    Some("run-id"),
    book_quality_review_run_dispatched_status(),
    "summary",
    42UL,
  )
  assert_eq(run.book_id, "book-run")
  assert_eq(run.packet_path, "/tmp/packet.json")
  assert_eq(run.result_path, "/tmp/results/book-run.md")
  assert_true(run.proposal_id is Some("proposal-run"))
  assert_true(run.run_id is Some("run-id"))
  assert_eq(run.status, book_quality_review_run_dispatched_status())
  assert_eq(run.summary, "summary")
  assert_eq(run.generated_at_ms, 42UL)
}

///|
test "book quality review dispatch helpers expose run status and launch summary" {
  assert_eq(
    book_quality_review_status_for_imported_run(Some("run-1")),
    book_quality_review_run_dispatched_status(),
  )
  assert_eq(
    book_quality_review_status_for_imported_run(None),
    book_quality_review_run_queued_status(),
  )
  assert_eq(
    book_quality_review_summary_with_launch_command(
      "Imported proposal.",
      Some("moon run cmd/main -- proposal run run-1"),
    ),
    "Imported proposal. Detached runner: moon run cmd/main -- proposal run run-1",
  )
  assert_eq(
    book_quality_review_summary_with_launch_command("Imported proposal.", None),
    "Imported proposal.",
  )
}

///|
async test "book quality review packet helpers expose paths and result state" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-packet-helper-wbtest",
  )
  let result_dir = "\{root}/results"
  assert_eq(
    book_quality_review_skill_path("\{root}/review"),
    "\{root}/review/BOOK_QUALITY_REVIEW_SKILL.md",
  )
  assert_false(
    book_quality_ai_review_result_exists(result_dir, "course-example"),
  )
  write_text_file(
    book_quality_ai_review_result_path(result_dir, "course-example"),
    "ai_quality_score: 88\n",
  )
  assert_true(
    book_quality_ai_review_result_exists(result_dir, "course-example"),
  )
}

///|
test "book quality dispatch messages stay stable" {
  assert_eq(
    active_book_quality_review_message(2),
    "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=2",
  )
  assert_eq(
    no_pending_book_quality_review_message("/tmp/results"),
    "No pending AI semantic book-quality review remains. Results are stored under /tmp/results.",
  )
}
