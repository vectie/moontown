///|
async test "semantic review bridge skips archived hidden internal books" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-bridge-archived-wbtest",
  )
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  let workspace_root = "\{root}/books/codex-smoke-pdf-watch"
  write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  write_book_quality_ai_review_result_fixture(
    result_dir,
    "codex-smoke-pdf-watch",
    20,
    next_repair_task="Repair should not be queued for an archived smoke book.",
  )
  @moonbook.save_catalog_file(catalog_path, [
    book_quality_catalog_entry(
      id="codex-smoke-pdf-watch",
      name="Smoke PDF Watch",
      purpose="Archived proof artifact.",
      workspace_root~,
      tags=["research", "archived", "hidden", "internal"],
    ),
  ])
  let state = @core.empty_state(
    @core.TownConfig::new(
      id="bridge-archived-test",
      name="Bridge Archived Test",
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="codex-smoke-pdf-watch",
      name="Smoke PDF Watch",
      purpose="Archived proof artifact.",
      workspace_root~,
      tags=["research", "archived", "hidden", "internal"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [
    @core.StandingGoal::new(
      id="book-quality-repair-codex-smoke-pdf-watch",
      title="Repair archived smoke book",
      prompt="This should be retired because the book is archived.",
      target_book_id=Some("codex-smoke-pdf-watch"),
      cadence_ticks=60,
      next_due_tick=42,
      enabled=true,
      source_policy=@book_quality.web_first_policy(),
      quality_threshold=80,
    ),
  ])
  let summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(
    summary.contains(
      "No weak AI semantic book-quality review needed repair bridging.",
    ),
  )
  assert_true(summary.contains("Retired 1 stale repair goal"))
  assert_false(
    @fs.exists("\{workspace_root}/wiki/reviews/book-quality-repair.md"),
  )
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, "book-quality-repair-codex-smoke-pdf-watch")
  assert_false(goals[0].enabled)
  assert_true(@fs.exists(bridge_path))
}
