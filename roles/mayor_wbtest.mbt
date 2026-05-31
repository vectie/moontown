///|
test "mayor keeper packet ids stay compact for long task ids" {
  let task_id = "goal-own-only-the-moonbook-research-lane-build-durable-source-entity-concept-and-synthesis-coverage-for-this-lane-cross-reference-other-lanes-only-through-durable-outputs-global-town-goal-research-moontown-moonbook-and-moonclaw-bootstrap_gather"
  let packet_id = compact_keeper_packet_id("research-moonbook", task_id)
  assert_true(packet_id.has_prefix("keeper-"))
  assert_true(packet_id.length() < 96)
  assert_true(!packet_id.contains(task_id))
}

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
  assert_eq(
    moonclaw_profile_for_task(task),
    "moontown_research_bootstrap_worker",
  )
}

///|
test "wenyu civic book routes generic maintenance task to civic worker" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let entry = @civic.wenyu_civic_book_entry(service)
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
    moonclaw_profile_for_entry_task(entry, task),
    "wenyu_civic_service_worker",
  )
}

///|
test "planbook maintenance routes to planbook repair worker" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="plan-moontown-quality",
    name="Moontown PlanBook",
    purpose="Plan and repair Moontown quality gaps.",
    workspace_root=".moontown/books/plan-moontown-quality",
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
    moonclaw_profile_for_entry_task(entry, task),
    "planbook_repair_worker",
  )
}

///|
test "mayor launches queued packet-ready execution when retry tick is due" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="queued-task",
      book_id="book",
      packet_id="queued",
      packet_path="",
      status=@core.TaskExecutionStatus::PacketReady,
      summary="queued by concurrency cap",
      output_contract="moontown.queued.execution.v1",
      next_retry_tick=Some(10),
    ),
  )
  let packet = Mayor::new().supervise(state, 10)
  assert_eq(packet.directives.length(), 1)
  assert_eq(packet.directives[0].kind, "retry-execution")
  assert_eq(packet.directives[0].task_id, "queued-task")
}
