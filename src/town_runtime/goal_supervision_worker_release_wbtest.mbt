///|
test "review queued execution releases worker for future daemon dispatch" {
  assert_eq(worker_status_for_execution(ReviewQueued), Idle)
}

///|
test "failed terminal execution releases worker for future daemon dispatch" {
  assert_eq(worker_status_for_execution(Failed), Idle)
}

///|
test "mayor releases blocked worker after latest terminal execution" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="watcher",
      name="Watcher",
      book_id="research-opc",
      role=Watcher,
      status=Blocked,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-3225",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-timeout"),
      status=Failed,
      summary="MoonClaw run did not settle within the supervision window.",
      output_contract="standing-watch",
      assigned_worker_id=Some("watcher"),
    ),
  )
  release_orphaned_blocked_workers(state)
  assert_eq(state.workers[0].status, Idle)
  assert_true(state.events.any(fn(event) { event.kind == "recovery" }))
}

///|
test "mayor releases running worker when latest assigned execution is terminal" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="watcher",
      name="Watcher",
      book_id="research-opc",
      role=Watcher,
      status=Running,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-3225",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-timeout"),
      status=Failed,
      summary="MoonClaw run did not settle within the supervision window.",
      output_contract="standing-watch",
      assigned_worker_id=Some("watcher"),
    ),
  )
  release_orphaned_blocked_workers(state)
  assert_eq(state.workers[0].status, Idle)
}

///|
test "mayor releases stale worker even when retry is scheduled" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="watcher",
      name="Watcher",
      book_id="research-opc",
      role=Watcher,
      status=Blocked,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-4050",
      book_id="research-opc",
      packet_id="pending",
      packet_path="",
      status=Stale,
      summary="missed heartbeat",
      output_contract="standing-watch-live-snapshot",
      assigned_worker_id=Some("watcher"),
      next_retry_tick=Some(204),
    ),
  )
  release_orphaned_blocked_workers(state)
  assert_eq(state.workers[0].status, Idle)
}

///|
test "failed execution record keeps assigned worker for cleanup" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="Research OPC",
    purpose="watch opc",
    workspace_root="/tmp/research-opc",
  )
  let task = @moonbook.BookTask::new(
    id="standing-watch-opc-news-tick-1",
    title="Standing watch",
    kind="standing-watch",
    prompt="watch",
    priority=95,
    requires_review=false,
  )
  let execution = failed_execution_record(
    entry,
    task,
    "failed",
    assigned_worker_id=Some("watcher"),
  )
  assert_true(execution.assigned_worker_id == Some("watcher"))
  assert_eq(worker_status_for_execution(execution.status), Idle)
}
