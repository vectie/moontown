///|
async test "book quality repair bridge context loads and persists bridge state" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-bridge-context-wbtest",
  )
  let catalog_path = @storage.moontown_product_artifact_for_workspace_root(
    root, "moonbooks.json",
  )
  let snapshot_path = "\{root}/town.json"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  @support.write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  @moonbook.save_catalog_file(catalog_path, [
    book_quality_catalog_entry(
      id="research-robotics",
      name="Robotics Research",
      purpose="Research embodied robotics.",
      workspace_root="\{root}/books/research-robotics",
      tags=["research"],
    ),
    book_quality_catalog_entry(
      id="archived-research",
      name="Archived Research",
      purpose="Archived proof artifact.",
      workspace_root="\{root}/books/archived-research",
      tags=["research", "archived"],
    ),
  ])
  @storage.save_snapshot_file(
    snapshot_path,
    @storage.snapshot_of(
      @core.empty_state(
        @core.TownConfig::new(id="bridge-context-test", name="Bridge Context"),
      ),
    ),
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [
    @core.StandingGoal::new(
      id="book-quality-repair-research-robotics",
      title="Repair book quality",
      prompt="Repair.",
      target_book_id=Some("research-robotics"),
      enabled=true,
    ),
  ])
  let context = load_book_quality_repair_bridge_context(
    catalog_path, snapshot_path,
  )
  assert_eq(context.current_tick, 41)
  assert_true(context.repairable_book_ids.contains("research-robotics"))
  assert_false(context.repairable_book_ids.contains("archived-research"))
  assert_eq(context.goals.length(), 1)
  assert_true(
    context.audit.scores.any(fn(score) { score.book_id == "research-robotics" }),
  )
  let repaired = [
    book_quality_repair_bridge_item_fixture(
      "research-robotics",
      @policy.research_type(),
      "\{root}/books/research-robotics",
    ),
  ]
  persist_book_quality_repair_bridge(context, bridge_path, repaired)
  assert_true(@fs.exists("\{root}/standing-goals.json"))
  let ledger_text = @support.read_text_or_empty(bridge_path)
  assert_true(ledger_text.contains("\"book_id\": \"research-robotics\""))
}
