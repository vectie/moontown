///|
async fn cleaned_book_quality_test_root(root : String) -> String {
  ignore_checked_command("rm", ["-rf", root])
  root
}

///|
fn book_quality_review_run_fixture(
  book_id : String,
  packet_path : String,
  result_path : String,
  proposal_id : String?,
  run_id : String?,
  status : String,
  summary : String,
  generated_at_ms : UInt64,
) -> BookQualityReviewRun {
  BookQualityReviewRun::{
    book_id,
    packet_path,
    result_path,
    proposal_id,
    run_id,
    status,
    summary,
    generated_at_ms,
  }
}

///|
fn book_quality_review_run_update(
  base : BookQualityReviewRun,
  book_id? : String? = None,
  packet_path? : String? = None,
  result_path? : String? = None,
  proposal_id? : String? = None,
  run_id? : String? = None,
  status? : String? = None,
  summary? : String? = None,
  generated_at_ms? : UInt64? = None,
) -> BookQualityReviewRun {
  BookQualityReviewRun::{
    book_id: book_id.unwrap_or(base.book_id),
    packet_path: packet_path.unwrap_or(base.packet_path),
    result_path: result_path.unwrap_or(base.result_path),
    proposal_id: match proposal_id {
      Some(value) => Some(value)
      None => base.proposal_id
    },
    run_id: match run_id {
      Some(value) => Some(value)
      None => base.run_id
    },
    status: status.unwrap_or(base.status),
    summary: summary.unwrap_or(base.summary),
    generated_at_ms: generated_at_ms.unwrap_or(base.generated_at_ms),
  }
}

///|
fn book_quality_catalog_entry(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
  tags~ : Array[String],
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(id~, name~, purpose~, workspace_root~, tags~)
}

///|
fn book_quality_score_fixture(
  book_id : String,
  book_type : String,
  workspace_root : String,
) -> BookQualityScore {
  BookQualityScore::{
    book_id,
    title: book_id,
    book_type,
    workspace_root,
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
    next_action: "Repair the book.",
  }
}

///|
fn book_quality_repair_bridge_item_fixture(
  book_id : String,
  book_type : String,
  workspace_root : String,
) -> BookQualityRepairBridgeItem {
  BookQualityRepairBridgeItem::{
    book_id,
    book_type,
    workspace_root,
    semantic_score: 72,
    semantic_grade: "usable",
    repair_owner: "moonbook",
    next_repair_task: "Repair the book.",
    review_result_path: "\{workspace_root}/review-result.md",
    book_review_path: "\{workspace_root}/wiki/reviews/book-quality-repair.md",
    standing_goal_id: book_quality_repair_goal_id(book_id),
    status: book_quality_review_run_queued_status(),
    generated_at_ms: 1UL,
  }
}

///|
async fn write_book_quality_ai_review_result_fixture(
  result_dir : String,
  book_id : String,
  score : Int,
  grade? : String = "weak",
  repair_owner? : String = "moonbook",
  next_repair_task? : String = "improve source synthesis",
) -> Unit {
  write_text_file(
    book_quality_ai_review_result_path(result_dir, book_id),
    [
      "ai_quality_score: \{score}",
      "ai_quality_grade: \{grade}",
      "repair_owner: \{repair_owner}",
      "next_repair_task: \{next_repair_task}",
    ].join("\n"),
  )
}

///|
fn assert_required_path_contract(
  paths : Array[BookQualityRequiredPath],
  expected_length : Int,
  expected : Array[BookQualityRequiredPath],
) -> Unit raise {
  assert_eq(paths.length(), expected_length)
  for item in expected {
    assert_true(
      paths.any(fn(path) {
        path.relative == item.relative && path.points == item.points
      }),
    )
  }
}

///|
async fn seed_complete_civic_service_workspace(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.schema_pages {
    write_text_file("\{root}/\{path}", "# Schema\n")
  }
  for path in service.wiki_pages {
    write_text_file("\{root}/\{path}", "# Wiki\n")
  }
  for path in service.review_queues {
    write_text_file("\{root}/\{path}", "# Review\n")
  }
  for path in civic_service_workspace_required_paths(service) {
    write_text_file("\{root}/\{path.relative}", "# Required\n")
  }
  write_text_file(civic_service_result_path(service, root~), "{}\n")
}

///|
async fn write_book_quality_review_run_ledger(
  path : String,
  runs : Array[BookQualityReviewRun],
) -> Unit {
  write_text_file(
    path,
    book_quality_review_run_ledger_to_text(BookQualityReviewRunLedger::{ runs, }),
  )
}

///|
fn assert_book_quality_review_run_status_traits(
  status : String,
  bucket : String,
  in_progress : Bool,
  terminal : Bool,
  problem : Bool,
) -> Unit raise {
  assert_eq(book_quality_review_run_status_bucket(status), bucket)
  assert_eq(book_quality_review_run_in_progress_status(status), in_progress)
  assert_eq(book_quality_review_run_terminal_status(status), terminal)
  assert_eq(book_quality_review_run_problem_status(status), problem)
}
