///|
test "archive catalog policy adds hidden archival tags once" {
  let catalog = [
    @moonbook.BookCatalogEntry::new(
      id="research-pdfs",
      name="PDF Watch",
      purpose="Watch external PDFs.",
      workspace_root="/tmp/research-pdfs",
      tags=["research", "archived"],
      skills=["pdf-evidence-watch"],
    ),
    @moonbook.BookCatalogEntry::new(
      id="other-book",
      name="Other Book",
      purpose="Unrelated.",
      workspace_root="/tmp/other-book",
    ),
  ]
  let archived = archive_pdf_evidence_watch_catalog_entry(
    catalog, "research-pdfs", "No longer needed.",
  )
  match @moonbook.entry_for_book_id(archived, "research-pdfs") {
    Some(entry) => {
      assert_true(entry.purpose.contains("Archived: No longer needed."))
      assert_true(entry.tags.contains("archived"))
      assert_true(entry.tags.contains("hidden"))
      assert_true(entry.tags.contains("internal"))
      assert_eq(entry.tags.length(), 4)
    }
    None => fail("expected archived catalog entry")
  }
  match @moonbook.entry_for_book_id(archived, "other-book") {
    Some(entry) => assert_false(entry.tags.contains("archived"))
    None => fail("expected unrelated catalog entry")
  }
}

///|
test "archive standing goal policy disables watch and book quality goals" {
  let goals = [
    @core.StandingGoal::new(
      id=pdf_evidence_watch_goal_id("research-pdfs"),
      title="Watch PDFs",
      prompt="Watch PDFs.",
      target_book_id=Some("research-pdfs"),
      cadence_ticks=30,
      next_due_tick=1,
      enabled=true,
    ),
    @core.StandingGoal::new(
      id=@book_quality.repair_goal_id("research-pdfs"),
      title="Repair quality",
      prompt="Repair quality.",
      target_book_id=Some("research-pdfs"),
      cadence_ticks=30,
      next_due_tick=1,
      enabled=true,
    ),
    @core.StandingGoal::new(
      id="watch-other",
      title="Other",
      prompt="Other.",
      target_book_id=Some("other-book"),
      cadence_ticks=30,
      next_due_tick=1,
      enabled=true,
    ),
  ]
  let disabled = disable_pdf_evidence_watch_book_standing_goals(
    goals, "research-pdfs",
  )
  assert_eq(
    count_disabled_pdf_evidence_watch_book_standing_goals(
      goals, disabled, "research-pdfs",
    ),
    2,
  )
  for goal in disabled {
    if goal.target_book_id == Some("research-pdfs") {
      assert_false(goal.enabled)
    }
    if goal.id == "watch-other" {
      assert_true(goal.enabled)
    }
  }
}
