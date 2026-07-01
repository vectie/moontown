///|
test "research bootstrap task uses direct research bootstrap profile" {
  let task = @moonbook.BookTask::new(
    id="goal-research-opc-research-bootstrap-ingest",
    goal=Some("Research latest OPC news"),
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    priority=100,
    requires_review=true,
    target_pages=["raw/bootstrap/research-question.md"],
  )
  assert_eq(keeper_profile_for_task(task), "moontown_research_bootstrap_worker")
}

///|
test "civic book routes generic maintenance task to civic worker by policy type" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Wenyu Policy Hall",
    purpose="Civic protocol place.",
    workspace_root="books/wenyu-policy-hall",
    tags=["civic-service"],
  )
  let task = @moonbook.BookTask::new(
    id="wenyu-policy-hall-goal-maintain-the-book-and-produce-a-keeper-ready-domain-summary-ingest-followup",
    goal=Some("Maintain Wenyu policy hall"),
    title="Maintain the book and produce a keeper-ready domain summary",
    kind="ingest",
    prompt="Maintain this civic building workspace.",
    priority=80,
    requires_review=true,
  )
  assert_eq(
    keeper_profile_for_entry_task(entry, task),
    @moonclaw_policy.civic_keeper_profile(),
  )
}

///|
test "planbook maintenance routes to planbook repair worker by policy type" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="plan-moontown-quality",
    name="Moontown PlanBook",
    purpose="Plan and repair Moontown quality gaps.",
    workspace_root="books/plan-moontown-quality",
    tags=["planning"],
    skills=["code-plan"],
  )
  let task = @moonbook.BookTask::new(
    id="plan-moontown-quality-goal-maintain-review",
    goal=Some("Maintain planbook quality"),
    title="Review PlanBook quality",
    kind="review",
    prompt="Review planbook quality.",
    priority=80,
    requires_review=true,
  )
  assert_eq(
    keeper_profile_for_entry_task(entry, task),
    @moonclaw_policy.planbook_keeper_profile(),
  )
}
