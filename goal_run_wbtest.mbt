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

///|
test "deep report quality gate accepts research-shaped report" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-moonbook",
    name="MoonBook Research",
    purpose="test",
    workspace_root="/tmp/moonbook",
  )
  let report = "# MoonBook: Deep Research Analysis\n\n## Executive Summary\n\nMoonBook is a lane-specific research subject.\n\n## Context\n\nText.\n\n## Architecture\n\n| Layer | Role |\n| --- | --- |\n| Book | Memory |\n\n## Evidence\n\nText.\n\n## Integration\n\n```mermaid\nflowchart TB\nA-->B\n```\n\n## Maturity\n\nText.\n\n## Risks\n\nText.\n\n## Trajectory\n\nText.\n"
  assert_eq(deep_report_quality_gaps(entry, report).length(), 0)
}

///|
test "deep report quality gate rejects shallow process output" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-moonclaw",
    name="MoonClaw Research",
    purpose="test",
    workspace_root="/tmp/moonclaw",
  )
  let report = "# Run Notes\n\n## Summary\n\nThis run is pending enrichment and has placeholder notes.\n"
  let gaps = deep_report_quality_gaps(entry, report)
  assert_true(gaps.length() >= 5)
}
