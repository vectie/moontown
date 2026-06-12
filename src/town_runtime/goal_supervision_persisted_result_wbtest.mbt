///|
async test "review queue closes when MoonBook already persisted non-review result" {
  let root = "/tmp/moontown-persisted-non-review-close"
  let snapshot_path = "\{root}/town.json"
  let result = @moonbook.BookResult::new(
    task_id="goal-course-bootstrap",
    summary="Course bootstrap persisted with durable artifacts.",
    artifacts=["raw/bootstrap/course-outline.md"],
    memory_candidates=[
      @moonbook.MemoryCandidate::new(
        kind="synthesis",
        title="Course outline",
        detail="Durable course outline.",
        durable=true,
        target_page=Some("synthesis/course-outline.md"),
      ),
    ],
    requires_review=false,
    notify_town=false,
  )
  @support.write_text_file(
    "\{root}/book-results/goal-course-bootstrap.json",
    result.to_json().stringify(),
  )
  let state = goal_supervision_test_state()
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="goal-course-bootstrap",
      book_id="course-book",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-course"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="pending_review=1",
      output_contract="course",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [], snapshot_path~)
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains(
      "keeper_auto_triage: persisted_non_review_result",
    ),
  )
}

///|
async test "failed execution closes into review when MoonBook already persisted review result" {
  let root = "/tmp/moontown-persisted-review-failed-close"
  let snapshot_path = "\{root}/town.json"
  let result = @moonbook.BookResult::new(
    task_id="goal-synthesis",
    summary="Synthesis persisted but requires keeper review.",
    artifacts=["run-synthesis"],
    memory_candidates=[],
    requires_review=true,
    notify_town=false,
  )
  @support.write_text_file(
    "\{root}/book-results/goal-synthesis.json",
    result.to_json().stringify(),
  )
  let state = goal_supervision_test_state()
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="goal-synthesis",
      book_id="coding",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="ExternalProposalPacket: context_pages must not be empty",
      output_contract="wiki.update",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [], snapshot_path~)
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(
    state.executions[0].summary.contains(
      "keeper_auto_triage: persisted_terminal_result",
    ),
  )
  assert_true(state.events.any(fn(event) { event.kind == "recovery" }))
}
