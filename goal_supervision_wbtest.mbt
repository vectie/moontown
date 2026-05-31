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
  assert_true(execution.assigned_worker_id == Some("watcher"))
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

///|
async test "standing watch review queue auto-closes no-change keeper markers" {
  let root = "/tmp/moontown-standing-watch-auto-triage-no-change"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = @core.StandingGoal::new(
    id="watch-auto-triage",
    title="Auto triage",
    prompt="watch auto triage",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    quality_threshold=80,
  )
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-auto
      $|- Decision: `no_change`
      $|- Delta score: `12`
      $|- New source count: `0`
      $|- Next check hint: `slower`
      $|- Checked sources count: `5`
      $|- New sources found: `1`
      $|- Accepted facts count: `0`
      $|- Rejected facts count: `1`
      $|- Wiki pages changed count: `0`
      $|- Book changed: `no`
      $|- Summary: standing_goal_decision: no_change
      $|delta_score: 12
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
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-auto-triage-tick-12",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-auto"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Workflow completed",
      output_contract="standing-watch",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains("keeper_auto_triage: accepted"),
  )
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
  let records = @storage.load_watcher_run_records(
    "watch-auto-triage",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some("standing-watch-auto-triage-tick-12") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
}

///|
async test "standing watch auto triage keeps weak updates in review" {
  let root = "/tmp/moontown-standing-watch-auto-triage-weak-update"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = @core.StandingGoal::new(
    id="watch-weak-update",
    title="Weak update",
    prompt="watch weak update",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    quality_threshold=80,
  )
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-weak
      $|- Decision: `update`
      $|- Delta score: `42`
      $|- New source count: `1`
      $|- Next check hint: `review`
      $|- Checked sources count: `5`
      $|- New sources found: `1`
      $|- Accepted facts count: `1`
      $|- Rejected facts count: `1`
      $|- Wiki pages changed count: `1`
      $|- Book changed: `yes`
      $|- Summary: standing_goal_decision: update
      $|delta_score: 42
      $|new_source_count: 1
      $|book_changed: yes
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
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-weak-update-tick-12",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-weak"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Workflow completed",
      output_contract="standing-watch",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: update"),
  )
  assert_true(
    !state.executions[0].summary.contains("keeper_auto_triage: accepted"),
  )
}

///|
async test "standing watch auto triage closes empty persisted book result" {
  let root = "/tmp/moontown-standing-watch-auto-triage-empty-result"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = @core.StandingGoal::new(
    id="watch-empty-result",
    title="Empty result",
    prompt="watch empty result",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
  )
  let result = @moonbook.BookResult::new(
    task_id="standing-watch-empty-result-tick-12",
    summary="MoonClaw run completed: Workflow completed workspace=/tmp/run",
    artifacts=["run-empty"],
    memory_candidates=[],
    requires_review=false,
    notify_town=false,
  )
  write_text_file(
    "\{root}/book-results/standing-watch-empty-result-tick-12.json",
    result.to_json().stringify(),
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
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-empty-result-tick-12",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-empty"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Workflow completed",
      output_contract="standing-watch",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
  assert_true(
    state.executions[0].summary.contains(
      "empty, non-review operational completion",
    ),
  )
}

///|
async test "failed standing watch closes when MoonBook has terminal no-change marker" {
  let root = "/tmp/moontown-standing-watch-failed-marker-recovery"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = @core.StandingGoal::new(
    id="watch-failed-marker",
    title="Failed marker",
    prompt="watch failed marker",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    quality_threshold=80,
  )
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-recovered
      $|- Decision: `no_change`
      $|- Delta score: `8`
      $|- New source count: `0`
      $|- Next check hint: `slower`
      $|- Checked sources count: `10`
      $|- New sources found: `3`
      $|- Accepted facts count: `0`
      $|- Rejected facts count: `3`
      $|- Wiki pages changed count: `0`
      $|- Book changed: `no`
      $|- Summary: standing_goal_decision: no_change
      $|delta_score: 8
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
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-failed-marker-tick-12",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-recovered"),
      status=@core.TaskExecutionStatus::Failed,
      summary="MoonClaw run was indexed as Running, but no live process was found.",
      output_contract="standing-watch",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains("keeper_auto_recovery: accepted"),
  )
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
  let records = @storage.load_watcher_run_records(
    "watch-failed-marker",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some("standing-watch-failed-marker-tick-12") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
}

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
  write_text_file(
    "\{root}/book-results/goal-course-bootstrap.json",
    result.to_json().stringify(),
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
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
  write_text_file(
    "\{root}/book-results/goal-synthesis.json",
    result.to_json().stringify(),
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
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
