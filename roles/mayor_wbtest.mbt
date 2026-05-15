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
