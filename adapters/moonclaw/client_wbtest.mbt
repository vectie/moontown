///|
test "proposal packet pins provider task spec for bootstrap ingest" {
  let task = @moonbook.BookTask::new(
    id="task-bootstrap",
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    priority=100,
    requires_review=true,
    target_pages=["raw/bootstrap/research-question.md"],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("\"extension_task_id\":\"task-bootstrap\""))
  assert_true(metadata.contains("\"bookapi_task_id\":\"task-bootstrap\""))
  assert_true(metadata.contains("\"kind\":\"bootstrap_gather\""))
  assert_true(metadata.contains("\"extension_task_kind\":\"bootstrap_gather\""))
}

///|
test "research bootstrap packet leaves web tools to the selected profile" {
  let task = @moonbook.BookTask::new(
    id="goal-research-opc-research-bootstrap-ingest",
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    priority=100,
    requires_review=true,
    target_pages=["raw/bootstrap/research-question.md"],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("MoonClaw raw research bootstrap artifacts"))
  assert_true(metadata.contains("raw/bootstrap/deep-report.md"))
  assert_true(!metadata.contains("\"tool_contract\""))
  assert_true(!metadata.contains("\"web_search\":false"))
  assert_true(!metadata.contains("wiki/sources"))
}
