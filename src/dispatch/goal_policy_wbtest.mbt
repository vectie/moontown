///|
fn dispatch_goal_policy_test_task(
  id : String,
  kind : String,
  priority : Int,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id~,
    title=id,
    kind~,
    prompt="Test task",
    priority~,
    requires_review=false,
  )
}

///|
test "dispatch classifies research and Wenyu goal text" {
  assert_true(research_goal_text("research OPC companies"))
  assert_true(research_goal_text("Compare Moontown MoonBook and MoonClaw"))
  assert_true(
    research_goal_text(
      "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
    ),
  )
  assert_true(wenyu_valley_goal_text("Wenyu Valley AI Innovation Town PRD"))
  assert_true(!research_goal_text("Create a bookkeeping workspace"))
  assert_true(!wenyu_valley_goal_text("Create a bookkeeping workspace"))
}

///|
test "dispatch prioritizes analysis before low-value research planning" {
  let tasks = [
    dispatch_goal_policy_test_task("planning", "planning", 1),
    dispatch_goal_policy_test_task("analysis", "analysis", 20),
    dispatch_goal_policy_test_task("ingest", "ingest", 0),
  ]
  let ordered = prioritized_book_tasks(tasks, "research EUV machines")
  assert_eq(ordered[0].id, "analysis")
  assert_eq(ordered[1].id, "ingest")
  assert_eq(ordered[2].id, "planning")
}

///|
test "dispatch gives review and planning higher weight for non-research goals" {
  let tasks = [
    dispatch_goal_policy_test_task("ingest", "ingest", 20),
    dispatch_goal_policy_test_task("review", "review", 20),
    dispatch_goal_policy_test_task("planning", "planning", 1),
  ]
  let ordered = prioritized_book_tasks(tasks, "maintain finance workspace")
  assert_eq(ordered[0].id, "review")
  assert_eq(ordered[1].id, "ingest")
  assert_eq(ordered[2].id, "planning")
}

///|
test "dispatch classifies research bootstrap book tasks for route consumers" {
  let task = @moonbook.BookTask::new(
    id="goal-research-opc-research-bootstrap-ingest",
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    priority=100,
    requires_review=true,
  )
  assert_true(research_bootstrap_book_task(task))
  assert_true(
    !research_bootstrap_book_task(
      @moonbook.BookTask::new(
        id="goal-research-opc-research-bootstrap-ingest",
        title="Bootstrap verified research coverage",
        kind="analysis",
        prompt="Bootstrap this book before answering the research question.",
        priority=100,
        requires_review=true,
      ),
    ),
  )
  assert_true(
    !research_bootstrap_book_task(
      @moonbook.BookTask::new(
        id="goal-research-opc-ingest",
        title="Bootstrap verified research coverage",
        kind="ingest",
        prompt="Bootstrap this book before answering the research question.",
        priority=100,
        requires_review=true,
      ),
    ),
  )
  assert_true(
    !research_bootstrap_book_task(
      @moonbook.BookTask::new(
        id="goal-research-opc-research-bootstrap-ingest",
        title="Bootstrap verified research coverage",
        kind="ingest",
        prompt="Bootstrap this operational book.",
        priority=100,
        requires_review=true,
      ),
    ),
  )
}
