///|
test "bootstrap planning keeps a single-task ingest-first limit" {
  assert_eq(research_bootstrap_task_limit(), 1)
}

///|
test "town goal slug is stable and filesystem safe" {
  assert_eq(
    town_goal_slug("Research Moontown, MoonBook, and MoonClaw!"),
    "research-moontown-moonbook-and-moonclaw",
  )
}

///|
test "lane status prefers review queued over complete" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-a",
      book_id="research-moonbook",
      packet_id="packet-a",
      packet_path="packet-a.json",
      status=@core.TaskExecutionStatus::Completed,
      summary="completed",
      output_contract="test",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-b",
      book_id="research-moonbook",
      packet_id="packet-b",
      packet_path="packet-b.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="quality gate",
      output_contract="test",
    ),
  )
  assert_eq(lane_research_status(state, "research-moonbook"), "review queued")
}
