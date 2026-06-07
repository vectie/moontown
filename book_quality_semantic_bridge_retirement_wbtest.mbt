///|
async test "semantic review bridge retires satisfied repair goals" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-bridge-retire-wbtest",
  )
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  let workspace_root = "\{root}/books/research-strong"
  write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  write_book_quality_ai_review_result_fixture(
    result_dir,
    "research-strong",
    91,
    grade="excellent",
    repair_owner="none",
    next_repair_task="No repair needed.",
  )
  @moonbook.save_catalog_file(catalog_path, [
    book_quality_catalog_entry(
      id="research-strong",
      name="Strong Research",
      purpose="Already repaired research book.",
      workspace_root~,
      tags=["research"],
    ),
  ])
  let state = @core.empty_state(
    @core.TownConfig::new(id="bridge-retire-test", name="Bridge Retire Test"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-strong",
      name="Strong Research",
      purpose="Already repaired research book.",
      workspace_root~,
      tags=["research"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [
    @core.StandingGoal::new(
      id="book-quality-repair-research-strong",
      title="Repair book quality: research-strong",
      prompt="Stale repair goal.",
      target_book_id=Some("research-strong"),
      cadence_ticks=60,
      next_due_tick=42,
      enabled=true,
      source_policy=book_quality_web_first_policy(),
      quality_threshold=80,
    ),
  ])
  let summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(summary.contains("Retired 1 stale repair goal"))
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, "book-quality-repair-research-strong")
  assert_false(goals[0].enabled)
  assert_false(
    @fs.exists("\{workspace_root}/wiki/reviews/book-quality-repair.md"),
  )
  assert_true(@fs.exists(bridge_path))
}
