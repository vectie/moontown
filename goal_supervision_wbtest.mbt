///|
test "review queued execution releases worker for future daemon dispatch" {
  assert_eq(
    worker_status_for_execution(@core.TaskExecutionStatus::ReviewQueued),
    @core.WorkerStatus::Idle,
  )
}

///|
test "failed terminal execution releases worker for future daemon dispatch" {
  assert_eq(
    worker_status_for_execution(@core.TaskExecutionStatus::Failed),
    @core.WorkerStatus::Idle,
  )
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
      role=@core.WorkerRole::Watcher,
      status=@core.WorkerStatus::Blocked,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-3225",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-timeout"),
      status=@core.TaskExecutionStatus::Failed,
      summary="MoonClaw run did not settle within the supervision window.",
      output_contract="standing-watch",
      assigned_worker_id=Some("watcher"),
    ),
  )
  release_orphaned_blocked_workers(state)
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
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
      role=@core.WorkerRole::Watcher,
      status=@core.WorkerStatus::Running,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-3225",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-timeout"),
      status=@core.TaskExecutionStatus::Failed,
      summary="MoonClaw run did not settle within the supervision window.",
      output_contract="standing-watch",
      assigned_worker_id=Some("watcher"),
    ),
  )
  release_orphaned_blocked_workers(state)
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
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
      role=@core.WorkerRole::Watcher,
      status=@core.WorkerStatus::Blocked,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-4050",
      book_id="research-opc",
      packet_id="pending",
      packet_path="",
      status=@core.TaskExecutionStatus::Stale,
      summary="missed heartbeat",
      output_contract="standing-watch-live-snapshot",
      assigned_worker_id=Some("watcher"),
      next_retry_tick=Some(204),
    ),
  )
  release_orphaned_blocked_workers(state)
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
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
  assert_eq(execution.assigned_worker_id, Some("watcher"))
  assert_eq(
    worker_status_for_execution(execution.status),
    @core.WorkerStatus::Idle,
  )
}

///|
async test "supervision does not keep unpolled running snapshot alive forever" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="standing-watch-opc-news-tick-4050",
      book_id="research-opc",
      title="Standing watch",
      prompt="watch",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Running,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-4050",
      book_id="research-opc",
      packet_id="pending",
      packet_path="",
      run_id=None,
      status=@core.TaskExecutionStatus::Running,
      summary="running snapshot without durable MoonClaw run",
      output_contract="standing-watch-live-snapshot",
      assigned_worker_id=Some("watcher"),
      heartbeat_tick=1,
      stale_after_tick=1,
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Stale)
  assert_true(state.executions[0].summary.contains("missed its heartbeat"))
}

///|
async test "standing watch retry completion appends corrected watcher record" {
  let root = "/tmp/moontown-standing-watch-retry-ledger-test"
  let snapshot_path = "\{root}/town.json"
  let goal = @core.StandingGoal::new(
    id="watch-retry-ledger",
    title="Retry ledger",
    prompt="watch retry ledger",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  write_text_file("\{root}/watchers/watch-retry-ledger.jsonl", "")
  let book_root = "\{root}/book"
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-retry
      $|- Decision: `no_change`
      $|- Delta score: `7`
      $|- New source count: `0`
      $|- Next check hint: `slower`
      $|- Checked sources count: `4`
      $|- New sources found: `1`
      $|- Accepted facts count: `0`
      $|- Rejected facts count: `1`
      $|- Wiki pages changed count: `0`
      $|- Book changed: `no`
      $|- Summary: standing_goal_decision: no_change
      $|delta_score: 7
      $|new_source_count: 0
      $|book_changed: no
    ),
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="Research OPC",
    purpose="watch opc",
    workspace_root=book_root,
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-retry-ledger-tick-12",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    run_id=Some("run-retry"),
    status=@core.TaskExecutionStatus::Completed,
    summary="Workflow completed",
    output_contract="standing-watch",
  )
  let observed = finalize_standing_watch_supervision_record(
    state,
    entry,
    execution,
    [goal],
    snapshot_path,
  )
  assert_true(observed.summary.contains("standing_goal_decision: no_change"))
  let records = @storage.load_watcher_run_records(
    "watch-retry-ledger",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some("standing-watch-retry-ledger-tick-12") &&
      record.run_id == Some("run-retry") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals[0].next_due_tick, 72)
}
