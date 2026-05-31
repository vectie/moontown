///|
test "bootstrap planning keeps a single-task ingest-first limit" {
  assert_eq(research_bootstrap_task_limit(), 1)
}

///|
test "Wenyu Valley PRD build goals trigger bootstrap coverage" {
  assert_true(
    is_research_goal(
      "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
    ),
  )
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

///|
test "Wenyu build stage emits implementation code and asset tasks" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="test",
    workspace_root="/tmp/wenyu-town-shell",
  )
  let tasks = wenyu_build_tasks(entry, "Build Wenyu Valley")
  assert_eq(tasks.length(), 4)
  assert_true(tasks.any(fn(task) { task.kind == "civic-service-workflow" }))
  assert_true(tasks.any(fn(task) { task.kind == "implementation-backlog" }))
  assert_true(tasks.any(fn(task) { task.kind == "code-patch" }))
  assert_true(tasks.any(fn(task) { task.kind == "image-asset" }))
}

///|
test "Wenyu service code and asset tasks route to the expected domains" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="test",
    workspace_root="/tmp/wenyu-town-shell",
  )
  let tasks = wenyu_build_tasks(entry, "Build Wenyu Valley")
  let service = tasks[0]
  let code = tasks[2]
  let asset = tasks[3]
  assert_eq(
    domain_for_book_task(entry, service),
    @core.WorkDomain::SocialExperiment,
  )
  assert_eq(domain_for_book_task(entry, code), @core.WorkDomain::Coding)
  assert_eq(domain_for_book_task(entry, asset), @core.WorkDomain::Coding)
}

///|
test "Wenyu civic task includes service skill and projection target" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Wenyu Valley / Policy Hall",
    purpose="test",
    workspace_root="/tmp/wenyu-policy-hall",
  )
  let tasks = wenyu_build_tasks(entry, "Build Wenyu Valley")
  let service = tasks[0]
  assert_eq(service.kind, "civic-service-workflow")
  assert_true(
    service.target_pages.contains("skills/civic-policy-researcher/SKILL.md"),
  )
  assert_true(service.target_pages.contains("book/moonbook-ui-state.json"))
  assert_true(service.prompt.contains("wenyu.civic.policy_service.v1"))
}

///|
test "Wenyu civic service plan skips research bootstrap" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Wenyu Valley / Policy Hall",
    purpose="test",
    workspace_root="/tmp/wenyu-policy-hall",
  )
  let bootstrap_like_task = @moonbook.BookTask::new(
    id="goal-wenyu-policy-hall-research-bootstrap-ingest",
    title="Bootstrap research",
    kind="research-bootstrap-ingest",
    prompt="Research Wenyu Valley Policy Hall.",
    priority=999,
    requires_review=false,
  )
  let plan = wenyu_civic_service_plan(
    entry,
    "Build Wenyu Valley AI Innovation Town",
    [bootstrap_like_task],
    1,
  )
  assert_true(!plan.bootstrap_active)
  assert_eq(plan.task_limit, 1)
  assert_eq(plan.tasks.length(), 1)
  assert_eq(plan.tasks[0].kind, "civic-service-workflow")
  assert_true(plan.tasks[0].prompt.contains("wenyu.civic.policy_service.v1"))
}

///|
async test "Wenyu civic books are excluded from research quality gates" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Wenyu Valley / Policy Hall",
    purpose="test",
    workspace_root="/tmp/wenyu-policy-hall",
  )
  assert_true(research_quality_gaps(entry).is_empty())
}

///|
test "Wenyu civic persistence creates service and review candidates" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-wenyu-policy-hall-civic-service",
    book_id="wenyu-policy-hall",
    packet_id="packet-civic",
    packet_path="packet-civic.json",
    run_id=Some("run-civic"),
    status=@core.TaskExecutionStatus::Completed,
    summary="civic_service_decision: update\nbook_changed: yes\nwiki_pages_changed_count: 2\naccepted_facts_count: 4\nreview_items_created_count: 1\nprojection_updated: yes\nnext_check_hint: normal\n\nUpdated cited policy checklist.",
    output_contract="wenyu.civic.policy_service.v1",
    context_pages=["raw/bootstrap/CIVIC_SERVICE_CONTRACT.md"],
    requires_review=true,
  )
  let summary = civic_persist_summary(service, execution)
  assert_true(summary.contains("Decision: `update`"))
  assert_true(summary.contains("Changed pages: 2"))
  let artifacts = civic_persist_artifacts(service, execution)
  assert_true(artifacts.contains("run-civic"))
  assert_true(artifacts.contains("book/moonbook-ui-state.json"))
  let candidates = civic_persist_memory_candidates(service, execution)
  assert_eq(candidates.length(), 2)
  assert_true(candidates[0].target_page == Some("civic/policy-hall.md"))
  assert_true(candidates[1].target_page == Some("reviews/policy-citations.md"))
}

///|
test "Wenyu deep report quality gate uses module topic" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="test",
    workspace_root="/tmp/wenyu-town-shell",
  )
  let report = "# Town Shell: Deep Research Analysis\n\n## Executive Summary\n\nThe town shell is the operator surface for Wenyu Valley.\n\n## Context\n\nText.\n\n## Architecture\n\n| Layer | Role |\n| --- | --- |\n| Shell | Runtime projection |\n\n## Evidence\n\nText.\n\n## Implementation\n\nText.\n\n## Integration\n\n```mermaid\nflowchart TB\nA-->B\n```\n\n## Maturity\n\nText.\n\n## Risks\n\nText.\n\n## Trajectory\n\nText.\n"
  assert_eq(deep_report_quality_gaps(entry, report).length(), 0)
}
