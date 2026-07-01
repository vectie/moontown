///|
async test "supervision clears transient dependency lock failures" {
  let state = @core.empty_state(@core.TownConfig::new(id="test", name="Test"))
  let book = @core.BookRef::new(
    id="coding",
    name="Coding",
    purpose="Coding workspace",
    workspace_root="/tmp/coding",
  )
  let task = @core.TownTask::new(
    id="goal-coding-analysis",
    book_id="coding",
    title="Coding analysis",
    prompt="Analyze coding workspace",
    domain=Research,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="goal-coding-analysis",
      book_id="coding",
      packet_id="packet",
      packet_path="packet.json",
      status=Failed,
      summary="Error: Failed to resolve the module dependency graph\nUnable to lock folder `/workspace/external/moonbook/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)",
      output_contract="test",
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(state, "goal-coding-analysis").unwrap()
  assert_eq(execution.status, Completed)
  assert_true(execution.summary.contains("transient_infrastructure_contention"))
}

///|
async test "supervision clears stale selfpatch transient dependency lock proof" {
  let state = @core.empty_state(@core.TownConfig::new(id="test", name="Test"))
  let book = @core.BookRef::new(
    id="coding",
    name="Coding",
    purpose="Coding workspace",
    workspace_root="/tmp/coding",
  )
  let task = @core.TownTask::new(
    id="selfpatch-runtime-transient-stale-proof-tick-999999",
    book_id="coding",
    title="Selfpatch stale proof",
    prompt="Probe stale transient runtime recovery",
    domain=Coding,
    status=Blocked,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="selfpatch-runtime-transient-stale-proof-tick-999999",
      book_id="coding",
      packet_id="selfpatch-runtime-transient-stale-proof",
      packet_path=@moonclaw.packet_file_path(
        @moonclaw.default_packet_directory(),
        "selfpatch-runtime-transient-stale-proof",
      ),
      run_id=Some("run-selfpatch-runtime-transient-stale-proof"),
      status=Stale,
      summary="Error: Failed to resolve the module dependency graph\nUnable to lock folder `/workspace/external/moonclaw/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)\nselfpatch_runtime_autonomy_probe: stale transient infrastructure failure should be reconciled by autonomous repair path",
      output_contract="standing-watch-live-snapshot",
      result_decision="pending",
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(
    state, "selfpatch-runtime-transient-stale-proof-tick-999999",
  ).unwrap()
  assert_eq(execution.status, Completed)
  assert_eq(execution.result_decision, "deferred-transient-infrastructure")
  assert_true(execution.next_retry_tick is None)
  assert_eq(state.tasks[0].status, Done)
  assert_true(execution.summary.contains("transient_infrastructure_contention"))
}

///|
async test "supervision clears transient dependency failures already queued for review" {
  let state = @core.empty_state(@core.TownConfig::new(id="test", name="Test"))
  let book = @core.BookRef::new(
    id="coding",
    name="Coding",
    purpose="Coding workspace",
    workspace_root="/tmp/coding",
  )
  let task = @core.TownTask::new(
    id="goal-coding-review",
    book_id="coding",
    title="Coding review",
    prompt="Review coding workspace",
    domain=Coding,
    status=Blocked,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="goal-coding-review",
      book_id="coding",
      packet_id="packet",
      packet_path="packet.json",
      status=ReviewQueued,
      summary="Mayor retry failed: Error: Failed to resolve the module dependency graph\nUnable to lock folder `/workspace/external/moonclaw/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: true",
      output_contract="test",
      requires_review=true,
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(state, "goal-coding-review").unwrap()
  assert_eq(execution.status, Completed)
  assert_eq(execution.requires_review, false)
  assert_eq(execution.result_decision, "deferred-transient-infrastructure")
  assert_eq(state.tasks[0].status, Done)
}

///|
async test "supervision clears moonclaw proposal storage aborts already queued for review" {
  let state = @core.empty_state(@core.TownConfig::new(id="test", name="Test"))
  let book = @core.BookRef::new(
    id="research-opc",
    name="Research OPC",
    purpose="OPC research",
    workspace_root="/tmp/research-opc",
  )
  let task = @core.TownTask::new(
    id="standing-book-quality-repair-research-opc-tick-15841",
    book_id="research-opc",
    title="Repair OPC quality",
    prompt="repair",
    domain=Research,
    status=Blocked,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-research-opc-tick-15841",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=ReviewQueued,
      summary="Mayor retry failed: RUNTIME ERROR: abort() called\ndeprecated.mbt:62 at @moonbitlang/core/builtin.StringBuilder::grow_if_necessary\n/workspace/external/moonclaw/job/system_storage.mbt:886 by @vectie/moonclaw/job.SystemStore::save_job_proposals",
      output_contract="standing-watch",
      requires_review=true,
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(
    state, "standing-book-quality-repair-research-opc-tick-15841",
  ).unwrap()
  assert_eq(execution.status, Completed)
  assert_eq(execution.requires_review, false)
  assert_true(execution.summary.contains("transient_infrastructure_contention"))
}
