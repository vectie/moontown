///|
test "final integration merges domain watches without dropping existing history" {
  let existing = [
    @core.StandingGoal::new(
      id="watch-opc-news",
      title="Old OPC",
      prompt="old",
      target_book_id=Some("research-opc"),
      cadence_ticks=30,
      next_due_tick=42,
      last_run_tick=Some(21),
      source_policy=@policy.web_first_policy(),
      quality_threshold=70,
    ),
  ]
  let specs = [
    {
      order: 1,
      domain: "OPC",
      form: "signal-watch",
      id: "watch-opc-news",
      title: "Track OPC",
      prompt: "new",
      target_book_id: "research-opc",
      cadence_ticks: 60,
      quality_threshold: 88,
      source_policy: @policy.web_first_policy(),
      initial_stagger_ticks: 3,
    },
    {
      order: 2,
      domain: "Agents",
      form: "signal-watch",
      id: "watch-ai-agents",
      title: "Track agents",
      prompt: "new agents",
      target_book_id: "research-ai-agents",
      cadence_ticks: 60,
      quality_threshold: 90,
      source_policy: @policy.web_first_policy(),
      initial_stagger_ticks: 9,
    },
  ]
  let merged = merge_final_integration_standing_goals(existing, specs, 100)
  assert_eq(merged.length(), 2)
  let opc = find_standing_goal_by_id(merged, "watch-opc-news").unwrap()
  assert_eq(opc.title, "Track OPC")
  assert_eq(opc.next_due_tick, 103)
  assert_true(opc.last_run_tick == Some(21))
  let agents = find_standing_goal_by_id(merged, "watch-ai-agents").unwrap()
  assert_true(agents.target_book_id == Some("research-ai-agents"))
  assert_eq(agents.next_due_tick, 109)
}
