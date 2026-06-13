///|
async test "semantic review bridge queues repair page and standing goal" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-bridge-wbtest",
  )
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  let workspace_root = "\{root}/books/research-robotics"
  @support.write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  write_book_quality_ai_review_result_fixture(
    result_dir,
    "research-robotics",
    32,
    next_repair_task="Build source-screen and evidence-matrix from verified robotics sources.",
  )
  @moonbook.save_catalog_file(catalog_path, [
    book_quality_catalog_entry(
      id="research-robotics",
      name="Robotics Research",
      purpose="Research embodied robotics.",
      workspace_root~,
      tags=["research"],
    ),
  ])
  let state = @core.empty_state(
    @core.TownConfig::new(id="bridge-test", name="Bridge Test"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-robotics",
      name="Robotics Research",
      purpose="Research embodied robotics.",
      workspace_root~,
      tags=["research"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [])
  let summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(
    summary.contains("Queued 1 new weak AI semantic book-quality repair"),
  )
  assert_true(
    @fs.exists("\{workspace_root}/wiki/reviews/book-quality-repair.md"),
  )
  let review = @support.read_text_or_empty(
    "\{workspace_root}/wiki/reviews/book-quality-repair.md",
  )
  assert_true(review.contains("Build source-screen and evidence-matrix"))
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, "book-quality-repair-research-robotics")
  assert_eq(goals[0].next_due_tick, 42)
  assert_eq(goals[0].source_policy, @policy.web_first_policy())
  assert_true(@fs.exists(bridge_path))
  let second_summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(
    second_summary.contains(
      "Refreshed 1 existing weak AI semantic book-quality repair",
    ),
  )
  assert_false(second_summary.contains("Queued 1 new weak"))
}
