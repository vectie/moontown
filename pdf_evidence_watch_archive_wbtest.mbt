///|
async test "archive pdf evidence watch book disables standing watch and hides catalog entry" {
  let base = "/tmp/moontown-pdf-evidence-watch-wbtest/archive"
  @support.ignore_checked_command("rm", ["-rf", base])
  let workspace_root = "\{base}/workspace"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let event_path = "\{base}/book-template-request-events.jsonl"
  ignore(
    bootstrap_pdf_evidence_watch_book(
      book_id="research-archive-pdfs",
      title="Archive PDF Watch",
      purpose="Temporary smoke book.",
      websites=["https://example.org/reports"],
      book_catalog_path=catalog_path,
      standing_goal_path=goals_path,
      workspace_root~,
    ),
  )
  let goals_before = @storage.load_or_create_standing_goals(path=goals_path)
  goals_before.push(
    @core.StandingGoal::new(
      id="book-quality-repair-research-archive-pdfs",
      title="Repair archived PDF watch",
      prompt="This repair goal should be retired with the archived book.",
      target_book_id=Some("research-archive-pdfs"),
      cadence_ticks=60,
      next_due_tick=1,
      enabled=true,
      source_policy="book-first",
    ),
  )
  @storage.save_standing_goals_file(goals_path, goals_before)
  let summary = archive_pdf_evidence_watch_book(
    book_id="research-archive-pdfs",
    reason="Smoke proof complete.",
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
    request_event_path=event_path,
  )
  assert_true(summary.contains("Archived PDF Evidence Watch book"))
  let status = inspect_pdf_evidence_watch_book(
    book_id="research-archive-pdfs",
    workspace_root~,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(status.has_catalog_entry)
  assert_true(status.has_standing_goal)
  assert_false(status.standing_goal_enabled)
  assert_false(status.ready)
  assert_true(
    summary.contains("Disabled standing goals targeting this book: `2`"),
  )
  let goals = @storage.load_or_create_standing_goals(path=goals_path)
  for goal in goals {
    if goal.id == "watch-research-archive-pdfs-pdfs" {
      assert_false(goal.enabled)
    }
    if goal.id == "book-quality-repair-research-archive-pdfs" {
      assert_false(goal.enabled)
    }
  }
  let catalog = @moonbook.load_or_create_catalog(path=catalog_path)
  match @moonbook.entry_for_book_id(catalog, "research-archive-pdfs") {
    Some(entry) => {
      assert_true(entry.tags.contains("archived"))
      assert_true(entry.tags.contains("hidden"))
      assert_true(entry.tags.contains("internal"))
    }
    None => fail("expected archived catalog entry")
  }
  let event_text = read_text_or_empty(event_path)
  assert_true(event_text.contains("\"status\":\"archived\""))
  assert_true(event_text.contains("archive-research-archive-pdfs"))
}
