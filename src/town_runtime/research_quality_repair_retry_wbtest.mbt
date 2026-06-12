///|
test "clean research projection recovers late failed bootstrap execution" {
  let state = @test_fixtures.research_quality_test_state()
  state.register_worker(
    @core.WorkerRef::new(
      id="worker-research-opc",
      name="Research Worker",
      book_id="research-opc",
      role=@core.WorkerRole::Harness,
      status=@core.WorkerStatus::Blocked,
    ),
  )
  let task_id = "goal-research-opc-research-bootstrap-ingest"
  state.enqueue_task(
    @core.TownTask::new(
      id=task_id,
      book_id="research-opc",
      title="Bootstrap verified research coverage",
      prompt="research",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Failed,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id~,
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="worker timeout",
      output_contract="research",
      assigned_worker_id=Some("worker-research-opc"),
    ),
  )
  complete_recovered_research_bootstrap_if_clean(state, "research-opc", [
    task_id,
  ])
  assert_eq(
    @core.find_execution(state, task_id).unwrap().status,
    @core.TaskExecutionStatus::Completed,
  )
  assert_eq(
    @core.find_task(state, task_id).unwrap().status,
    @core.TownTaskStatus::Done,
  )
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
  assert_true(state.events.any(fn(event) { event.kind == "recovery" }))
}

///|
async test "research quality gate schedules in-place repair retry" {
  let root = @test_fixtures.cleaned_research_quality_test_root(
    "/tmp/moontown-quality-retry",
  )
  let state = @test_fixtures.research_quality_test_state()
  state.register_book(
    @test_fixtures.llm_research_book_ref(
      "research-how-llm-are-trained-in-very-detail", root,
    ),
  )
  let task_id = "goal-research-how-llm-are-trained-in-very-detail-research-bootstrap-ingest"
  state.enqueue_task(
    @core.TownTask::new(
      id=task_id,
      book_id="research-how-llm-are-trained-in-very-detail",
      title="Bootstrap verified research coverage",
      prompt="research",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Done,
    ),
  )
  state.register_execution(
    @test_fixtures.research_quality_execution(
      task_id,
      "research-how-llm-are-trained-in-very-detail",
      @core.TaskExecutionStatus::Completed,
      "completed",
    ),
  )
  queue_research_quality_gate(state, state.books[0].id, [task_id], [
    "deep-report.md has fewer than 12k English words",
  ])
  let execution = @core.find_execution(state, task_id).unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(execution.next_retry_tick != None)
  assert_true(execution.summary.contains("auto_retry=true"))
  assert_eq(
    @core.find_task(state, task_id).unwrap().status,
    @core.TownTaskStatus::Blocked,
  )
  let trigger = @fs.read_file(root + "/raw/bootstrap/QUALITY_REPAIR.md").text()
  assert_true(trigger.contains("in-place review/repair"))
  assert_true(trigger.contains("do not create a new v1/v2/v3/v4 book"))
  @research_quality.write_research_quality_review_resolved(
    @test_fixtures.llm_research_catalog_entry(
      "research-how-llm-are-trained-in-very-detail", root,
    ),
    "post-run quality gate",
  )
  let resolved = @fs.read_file(root + "/raw/bootstrap/QUALITY_REPAIR.md").text()
  assert_true(resolved.contains("No active quality repair"))
  assert_true(!resolved.contains("deep-report.md has fewer than 12k"))
}

///|
async test "research quality gate retries failed bootstrap before version forking" {
  let root = @test_fixtures.cleaned_research_quality_test_root(
    "/tmp/moontown-quality-failed-retry",
  )
  let state = @test_fixtures.research_quality_test_state()
  state.register_book(
    @test_fixtures.llm_research_book_ref(
      "research-how-llms-are-trained-in-very-detail", root,
    ),
  )
  let task_id = "goal-research-how-llms-are-trained-in-very-detail-research-bootstrap-ingest"
  state.enqueue_task(
    @core.TownTask::new(
      id=task_id,
      book_id="research-how-llms-are-trained-in-very-detail",
      title="Bootstrap verified research coverage",
      prompt="research",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Failed,
    ),
  )
  state.register_execution(
    @test_fixtures.research_quality_execution(
      task_id,
      "research-how-llms-are-trained-in-very-detail",
      @core.TaskExecutionStatus::Failed,
      "MoonClaw run did not settle before deep-report.md existed.",
    ),
  )
  queue_research_quality_gate(state, state.books[0].id, [task_id], [
    "missing `raw/bootstrap/deep-report.md`",
  ])
  let execution = @core.find_execution(state, task_id).unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(execution.next_retry_tick != None)
  assert_eq(
    @core.find_task(state, task_id).unwrap().status,
    @core.TownTaskStatus::Blocked,
  )
  let trigger = @fs.read_file(root + "/raw/bootstrap/QUALITY_REPAIR.md").text()
  assert_true(trigger.contains("missing `raw/bootstrap/deep-report.md`"))
}
