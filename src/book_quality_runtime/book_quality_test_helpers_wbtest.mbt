///|
async fn cleaned_book_quality_test_root(root : String) -> String {
  @support.ignore_checked_command("rm", ["-rf", root])
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
) -> @book_quality.BookQualityReviewRun {
  {
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
  base : @book_quality.BookQualityReviewRun,
  book_id? : String? = None,
  packet_path? : String? = None,
  result_path? : String? = None,
  proposal_id? : String? = None,
  run_id? : String? = None,
  status? : String? = None,
  summary? : String? = None,
  generated_at_ms? : UInt64? = None,
) -> @book_quality.BookQualityReviewRun {
  {
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
) -> @book_quality.BookQualityScore {
  {
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
) -> @book_quality.BookQualityRepairBridgeItem {
  {
    book_id,
    book_type,
    workspace_root,
    semantic_score: 72,
    semantic_grade: "usable",
    repair_owner: "moonbook",
    next_repair_task: "Repair the book.",
    review_result_path: "\{workspace_root}/review-result.md",
    book_review_path: "\{workspace_root}/wiki/reviews/book-quality-repair.md",
    standing_goal_id: @book_quality.repair_goal_id(book_id),
    status: @book_quality.review_run_queued_status(),
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
  @support.write_text_file(
    @book_quality.review_result_path(result_dir, book_id),
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
  paths : Array[@book_quality.BookQualityRequiredPath],
  expected_length : Int,
  expected : Array[@book_quality.BookQualityRequiredPath],
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
  for
    path in [
      @book_quality.wiki_index_path(),
      @book_quality.projection_state_path(),
      "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md",
      "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
      "wiki/service/index.md",
      "wiki/service/protocol.md",
      "moonclaw.jobs.json",
    ] {
    @support.write_text_file("\{root}/\{path}", "# Civic Base\n")
  }
  for path in service.schema_pages {
    @support.write_text_file("\{root}/\{path}", "# Schema\n")
  }
  for path in service.wiki_pages {
    @support.write_text_file("\{root}/\{path}", "# Wiki\n")
  }
  for path in service.review_queues {
    @support.write_text_file("\{root}/\{path}", "# Review\n")
  }
  for
    path in [
      "wiki/ledgers/service-ledger.md",
      "wiki/ledgers/exchange-ledger.md",
      "wiki/history/service-history.md",
      service.skill_path,
    ] {
    @support.write_text_file("\{root}/\{path}", "# Required\n")
  }
  @support.write_text_file(
    "\{root}/book-results/goal-\{service.book_id}-civic-service.json",
    "{}\n",
  )
}

///|
async fn write_book_quality_review_run_ledger(
  path : String,
  runs : Array[@book_quality.BookQualityReviewRun],
) -> Unit {
  for run in runs {
    append_review_run(path, run)
  }
}
