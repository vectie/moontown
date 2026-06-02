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
async test "detached import receipt promotes proposal imported execution to run confirmed" {
  let root = "/tmp/moontown-detached-import-receipt-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let packet_path = "\{root}/packets/packet.json"
  write_text_file(
    packet_path + ".import.json",
    "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\"}",
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-10",
    book_id="research-opc",
    packet_id="packet",
    packet_path~,
    status=@core.TaskExecutionStatus::ProposalImported,
    summary="waiting for detached import",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=40,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(
    state,
    execution,
    11,
    launch_confirmed_run=false,
  )
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::RunConfirmed)
  assert_true(state.executions[0].run_id == Some("run-detached"))
  assert_true(state.executions[0].proposal_id == Some("proposal-detached"))
  assert_false(state.executions[0].summary.contains("Detached runner:"))
}

///|
async test "detached import receipt can launch confirmed run command" {
  let root = "/tmp/moontown-detached-import-launch-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let packet_path = "\{root}/packets/packet.json"
  write_text_file(
    packet_path + ".import.json",
    "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\"}",
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="Research OPC",
      purpose="Watch OPC",
      workspace_root=root,
    ),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-10",
    book_id="research-opc",
    packet_id="packet",
    packet_path~,
    status=@core.TaskExecutionStatus::ProposalImported,
    summary="waiting for detached import",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=40,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(
    state,
    execution,
    11,
    launch_command_override=Some(
      "moon -C ../moonclaw run cmd/main -- proposal run run-detached",
    ),
  )
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::RunConfirmed)
  assert_true(state.executions[0].summary.contains("Detached runner:"))
  assert_true(state.executions[0].summary.contains("proposal run run-detached"))
}

///|
async test "late inline detached receipt reconciles deferred no-run execution" {
  let root = "/tmp/moontown-late-detached-import-receipt-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let packet_path = "\{root}/packets/packet.json"
  let receipt =
    $|{"level":"Info","msg":"noise before json"}
    $|{
    $|  "proposal_id": "proposal-detached",
    $|  "run_id": "run-detached",
    $|  "status": "Succeeded"
    $|}

  write_text_file(packet_path + ".import.json", receipt)
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="Research OPC",
      purpose="Watch OPC",
      workspace_root=root,
    ),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-10",
    book_id="research-opc",
    packet_id="packet",
    packet_path~,
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
    last_command=Some(
      "moon proposal import > \{packet_path}.import.json 2> \{packet_path}.import.json.err",
    ),
  )
  state.register_execution(execution)
  reconcile_late_detached_import_receipts(state, 13)
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(state.executions[0].run_id == Some("run-detached"))
  assert_true(state.executions[0].proposal_id == Some("proposal-detached"))
  assert_true(state.executions[0].summary.contains("inline run finished"))
  assert_false(state.executions[0].summary.contains("Detached runner:"))
  assert_eq(state.executions[0].packet_path, packet_path)
}

///|
async test "late detached receipt appends terminal watcher ledger record" {
  let root = "/tmp/moontown-late-detached-watch-ledger-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/packet.json"
  let task_id = "standing-watch-late-ledger-tick-10"
  let receipt =
    $|{
    $|  "proposal_id": "proposal-detached",
    $|  "run_id": "run-detached",
    $|  "status": "Succeeded"
    $|}

  write_text_file(packet_path + ".import.json", receipt)
  let book_root = "\{root}/book"
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-late-ledger
      $|- Decision: `no_change`
      $|- Delta score: `0`
      $|- New source count: `0`
      $|- Summary: standing_goal_decision: no_change
      $|delta_score: 0
      $|new_source_count: 0
      $|book_changed: no
    ),
  )
  let goal = @core.StandingGoal::new(
    id="watch-late-ledger",
    title="Watch late ledger",
    prompt="watch late ledger",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=10,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Mayor deferred while detached import was pending.",
      task_id=Some(task_id),
      next_due_tick=70,
    ),
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="Research OPC",
    purpose="Watch OPC",
    workspace_root=book_root,
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id~,
    book_id="research-opc",
    packet_id="packet",
    packet_path~,
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
    last_command=Some(
      "moon proposal import > \{packet_path}.import.json 2> \{packet_path}.import.json.err",
    ),
  )
  state.register_execution(execution)
  reconcile_late_detached_import_receipts(
    state,
    13,
    catalog=[entry],
    snapshot_path~,
    standing_goals=[goal],
  )
  let records = @storage.load_watcher_run_records(
    "watch-late-ledger",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some(task_id) &&
      record.run_id == Some("run-detached") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
}

///|
async test "terminal detached watcher ledger reconciliation handles already completed receipt" {
  let root = "/tmp/moontown-terminal-detached-watch-ledger-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/packet.json"
  let task_id = "standing-watch-terminal-ledger-tick-10"
  write_text_file(
    packet_path + ".import.json",
    "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\",\"status\":\"Succeeded\"}",
  )
  let book_root = "\{root}/book"
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-terminal-ledger
      $|- Decision: `no_change`
      $|- Delta score: `0`
      $|- New source count: `0`
      $|- Summary: standing_goal_decision: no_change
      $|delta_score: 0
      $|new_source_count: 0
      $|book_changed: no
    ),
  )
  let goal = @core.StandingGoal::new(
    id="watch-terminal-ledger",
    title="Watch terminal ledger",
    prompt="watch terminal ledger",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=10,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Mayor deferred while detached import was pending.",
      task_id=Some(task_id),
      next_due_tick=70,
    ),
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="Research OPC",
    purpose="Watch OPC",
    workspace_root=book_root,
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id~,
      book_id="research-opc",
      packet_id="packet",
      packet_path~,
      run_id=Some("run-detached"),
      status=@core.TaskExecutionStatus::Completed,
      summary="Detached MoonClaw import completed; inline run finished.",
      output_contract="standing-watch",
      result_decision="completed",
    ),
  )
  reconcile_terminal_detached_watcher_ledgers(state, [entry], snapshot_path, [
    goal,
  ])
  let records = @storage.load_watcher_run_records(
    "watch-terminal-ledger",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some(task_id) &&
      record.run_id == Some("run-detached") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
  state.replace_execution(
    copy_execution_with(
      state.executions[0],
      summary="MoonClaw run run-detached completed: Workflow completed",
      requires_review=true,
    ),
  )
  reconcile_terminal_detached_watcher_ledgers(state, [entry], snapshot_path, [
    goal,
  ])
  let after_duplicate_attempt = @storage.load_watcher_run_records(
    "watch-terminal-ledger",
    dir="\{root}/watchers",
  )
  let mut terminal_count = 0
  for record in after_duplicate_attempt {
    if record.task_id == Some(task_id) &&
      record.run_id == Some("run-detached") &&
      record.decision != @core.WatcherDecisionKind::Deferred {
      terminal_count += 1
      assert_eq(record.decision, @core.WatcherDecisionKind::NoChange)
    }
  }
  assert_eq(terminal_count, 1)
}

///|
async test "orphaned deferred watcher record rehydrates detached import supervision" {
  let root = "/tmp/moontown-orphaned-deferred-watch-rehydrate-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/keeper-research-opc-standing-watch-opc-news-tick-50-abc.json"
  let receipt_path = packet_path + ".import.json"
  write_text_file(
    receipt_path, "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\",\"status\":\"Pending\"}",
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch opc",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=50,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Launched detached MoonClaw import for keeper-research-opc-standing-watch-opc-news-tick-50-abc; waiting for receipt \{receipt_path}.",
      task_id=Some("standing-watch-opc-news-tick-50"),
      next_due_tick=110,
    ),
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="Research OPC",
      purpose="watch opc",
      workspace_root=root,
    ),
  )
  rehydrate_orphaned_deferred_watcher_records(state, snapshot_path, [goal], 51)
  let execution = @core.find_execution(state, "standing-watch-opc-news-tick-50").unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::RunConfirmed)
  assert_eq(
    execution.packet_id,
    "keeper-research-opc-standing-watch-opc-news-tick-50-abc",
  )
  assert_true(execution.run_id == Some("run-detached"))
  assert_true(execution.proposal_id == Some("proposal-detached"))
  assert_true(execution.summary.contains("run run-detached is ready"))
  assert_true(
    @core.find_task(state, "standing-watch-opc-news-tick-50") is Some(_),
  )
}

///|
async test "orphaned deferred watcher record ignores already superseded terminal ledger" {
  let root = "/tmp/moontown-orphaned-deferred-watch-superseded-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/keeper-research-opc-standing-watch-opc-news-tick-50-abc.json"
  let receipt_path = packet_path + ".import.json"
  write_text_file(
    receipt_path, "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\",\"status\":\"Pending\"}",
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch opc",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=50,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Launched detached MoonClaw import; waiting for receipt \{receipt_path}.",
      task_id=Some("standing-watch-opc-news-tick-50"),
      next_due_tick=110,
    ),
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=50,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::NoChange,
      detail="standing_goal_decision: no_change",
      task_id=Some("standing-watch-opc-news-tick-50"),
      run_id=Some("run-detached"),
      next_due_tick=110,
    ),
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  rehydrate_orphaned_deferred_watcher_records(state, snapshot_path, [goal], 51)
  assert_true(
    @core.find_execution(state, "standing-watch-opc-news-tick-50") is None,
  )
}

///|
test "pending standing watch placeholder reconstructs keeper packet path" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-book-quality-repair-research-opc-tick-17902",
    book_id="research-opc",
    packet_id="pending-research-opc-standing-book-quality-repair-research-opc-tick-17902",
    packet_path="",
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
  )
  let packet_id = @roles.keeper_packet_id(execution.book_id, execution.task_id)
  assert_eq(detached_import_packet_id_for_execution(execution), packet_id)
  assert_eq(
    detached_import_packet_path_for_execution(execution),
    @moonclaw.packet_file_path(@moonclaw.default_packet_directory(), packet_id),
  )
}

///|
async test "late detached reconciliation hydrates missing packet handle without receipt" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-book-quality-repair-research-opc-tick-17902",
    book_id="research-opc",
    packet_id="pending-research-opc-standing-book-quality-repair-research-opc-tick-17902",
    packet_path="",
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
  )
  state.register_execution(execution)
  reconcile_late_detached_import_receipts(state, 13)
  let packet_id = @roles.keeper_packet_id(execution.book_id, execution.task_id)
  assert_eq(state.executions[0].packet_id, packet_id)
  assert_eq(
    state.executions[0].packet_path,
    @moonclaw.packet_file_path(@moonclaw.default_packet_directory(), packet_id),
  )
}

///|
async test "no run id live execution closes after stale window" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-llm-training-tick-10",
    book_id="research-llm",
    packet_id="packet",
    packet_path="/tmp/missing-packet.json",
    status=@core.TaskExecutionStatus::Running,
    summary="old live snapshot",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=12,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(state, execution, 13)
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Failed)
  assert_true(state.executions[0].summary.contains("no run id"))
  assert_eq(state.executions[0].result_decision, "deferred")
  assert_eq(state.executions[0].requires_review, false)
}

///|
async test "stale detached import failure keeps MoonClaw stderr evidence" {
  let root = "/tmp/moontown-detached-import-stderr-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let packet_path = "\{root}/packets/packet.json"
  let stderr =
    $|RUNTIME ERROR: abort() called
    $|deprecated.mbt:62 at @moonbitlang/core/builtin.StringBuilder::grow_if_necessary
    $|/Users/kq/Workspace/moonclaw/job/system_storage.mbt:886 by @vectie/moonclaw/job.SystemStore::save_job_proposals

  write_text_file(packet_path + ".import.json.err", stderr)
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-llm-training-tick-10",
    book_id="research-llm",
    packet_id="packet",
    packet_path~,
    status=@core.TaskExecutionStatus::ProposalImported,
    summary="old live snapshot",
    output_contract="standing-watch",
    heartbeat_tick=10,
    stale_after_tick=12,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(state, execution, 13)
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Failed)
  assert_true(state.executions[0].summary.contains("Detached import stderr:"))
  assert_true(
    state.executions[0].summary.contains("StringBuilder::grow_if_necessary"),
  )
  assert_true(
    state.executions[0].summary.contains("SystemStore::save_job_proposals"),
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
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(state.executions[0].summary.contains("no run id"))
  assert_eq(
    state.executions[0].result_decision,
    "deferred-transient-infrastructure",
  )
}

///|
async test "supervision uses short no-run-id window for restart residue" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="standing-watch-opc-news-tick-100",
      book_id="research-opc",
      title="Standing watch",
      prompt="watch",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Running,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-100",
      book_id="research-opc",
      packet_id="pending",
      packet_path="",
      run_id=None,
      status=@core.TaskExecutionStatus::Running,
      summary="running snapshot written before detached import finished",
      output_contract="standing-watch-live-snapshot",
      assigned_worker_id=Some("watcher"),
      heartbeat_tick=100,
      stale_after_tick=220,
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [], tick=Some(115))
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(state.executions[0].summary.contains("no run id"))
  assert_eq(
    state.executions[0].result_decision,
    "deferred-transient-infrastructure",
  )
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
async test "persisted watcher ledger closes stale snapshot execution" {
  let root = "/tmp/moontown-standing-watch-ledger-reconcile-test"
  let snapshot_path = "\{root}/town.json"
  let goal = @core.StandingGoal::new(
    id="watch-ledger-reconcile",
    title="Ledger reconcile",
    prompt="watch",
    target_book_id=Some("research-opc"),
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-ledger-reconcile",
    tick=42,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    detail="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nnext_check_hint: slower",
    task_id=Some("standing-watch-ledger-reconcile-tick-42"),
    run_id=Some("run-ledger"),
    next_due_tick=102,
  )
  @storage.append_watcher_run_record_file(
    "\{root}/watchers/watch-ledger-reconcile.jsonl",
    record,
  )
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
      task_id="standing-watch-ledger-reconcile-tick-42",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some("run-ledger"),
      status=@core.TaskExecutionStatus::Stale,
      summary="missed heartbeat",
      output_contract="standing-watch",
      assigned_worker_id=Some("watcher"),
      next_retry_tick=Some(48),
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains("reconciled_from_watcher_ledger"),
  )
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
}

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
    domain=@core.WorkDomain::Research,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="goal-coding-analysis",
      book_id="coding",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="Error: Failed to resolve the module dependency graph\nUnable to lock folder `/Users/kq/Workspace/moonbook/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)",
      output_contract="test",
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(state, "goal-coding-analysis").unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::Completed)
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
    domain=@core.WorkDomain::Coding,
    status=@core.TownTaskStatus::Blocked,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="goal-coding-review",
      book_id="coding",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Mayor retry failed: Error: Failed to resolve the module dependency graph\nUnable to lock folder `/Users/kq/Workspace/moonclaw/.mooncakes` for downloading dependencies\nOperation not permitted (os error 1)\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: true",
      output_contract="test",
      requires_review=true,
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(state, "goal-coding-review").unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::Completed)
  assert_eq(execution.requires_review, false)
  assert_eq(execution.result_decision, "deferred-transient-infrastructure")
  assert_eq(state.tasks[0].status, @core.TownTaskStatus::Done)
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
    domain=@core.WorkDomain::Research,
    status=@core.TownTaskStatus::Blocked,
  )
  state.register_book(book)
  state.enqueue_task(task)
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-research-opc-tick-15841",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Mayor retry failed: RUNTIME ERROR: abort() called\ndeprecated.mbt:62 at @moonbitlang/core/builtin.StringBuilder::grow_if_necessary\n/Users/kq/Workspace/moonclaw/job/system_storage.mbt:886 by @vectie/moonclaw/job.SystemStore::save_job_proposals",
      output_contract="standing-watch",
      requires_review=true,
    ),
  )
  reconcile_transient_dependency_failures(state)
  let execution = @core.find_execution(
    state, "standing-book-quality-repair-research-opc-tick-15841",
  ).unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::Completed)
  assert_eq(execution.requires_review, false)
  assert_true(execution.summary.contains("transient_infrastructure_contention"))
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
async test "standing watch auto triage appends corrected ledger after review observation" {
  let root = "/tmp/moontown-standing-watch-auto-triage-corrected-ledger"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = @core.StandingGoal::new(
    id="watch-auto-correct",
    title="Auto correct",
    prompt="watch auto correct",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    quality_threshold=80,
  )
  let task_id = "standing-watch-auto-correct-tick-12"
  let run_id = "run-auto-correct"
  @storage.append_watcher_run_record_file(
    "\{root}/watchers/watch-auto-correct.jsonl",
    @core.WatcherRunRecord::new(
      goal_id="watch-auto-correct",
      tick=12,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::NeedsReview,
      delta_score=0,
      new_source_count=0,
      detail="MoonClaw run \{run_id} completed: Workflow completed workspace=/tmp/run",
      task_id=Some(task_id),
      run_id=Some(run_id),
      next_due_tick=42,
    ),
  )
  write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    (
      $|### provider-standing-watch-auto-correct
      $|- Decision: `no_change`
      $|- Delta score: `0`
      $|- New source count: `0`
      $|- Summary: standing_goal_decision: no_change
      $|delta_score: 0
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
      task_id~,
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      run_id=Some(run_id),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Workflow completed",
      output_contract="standing-watch",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  let records = @storage.load_watcher_run_records(
    "watch-auto-correct",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some(task_id) &&
      record.run_id == Some(run_id) &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
}

///|
async test "standing watch review queue closes deferred infrastructure markers" {
  let root = "/tmp/moontown-standing-watch-deferred-review-close"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = @core.StandingGoal::new(
    id="watch-deferred",
    title="Deferred watcher",
    prompt="watch deferred",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    quality_threshold=80,
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
      task_id="standing-watch-deferred-tick-88",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Standing watch execution failed.\nRUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\nSystemStore::save_job_proposals\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true\nnext_check_hint: immediate",
      output_contract="standing-watch",
      requires_review=true,
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_eq(state.executions[0].requires_review, false)
  assert_true(
    state.executions[0].summary.contains("keeper_auto_triage: deferred"),
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

///|
async test "review queued standing watch keeps only latest review per goal active" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let goal = @core.StandingGoal::new(
    id="book-quality-repair-wenyu-resident-twins",
    title="Repair resident twins",
    prompt="repair",
    target_book_id=Some("wenyu-resident-twins"),
    cadence_ticks=60,
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-resident-twins-tick-10",
      book_id="wenyu-resident-twins",
      packet_id="packet-old",
      packet_path="old.json",
      run_id=Some("run-old"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="older review",
      output_contract="standing-watch",
      result_decision="NeedsReview",
      requires_review=true,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-resident-twins-tick-20",
      book_id="wenyu-resident-twins",
      packet_id="packet-new",
      packet_path="new.json",
      run_id=Some("run-new"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="newer review",
      output_contract="standing-watch",
      result_decision="NeedsReview",
      requires_review=true,
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [],
    "/tmp/moontown-review-superseded/town.json",
    [goal],
  )
  let old = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-resident-twins-tick-10",
  ).unwrap()
  let current = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-resident-twins-tick-20",
  ).unwrap()
  assert_eq(old.status, @core.TaskExecutionStatus::Completed)
  assert_eq(old.result_decision, "superseded-review")
  assert_true(!old.requires_review)
  assert_eq(current.status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(current.requires_review)
}

///|
async test "generic book-quality repair review stays in autonomous retry loop" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let goal = @core.StandingGoal::new(
    id="book-quality-repair-wenyu-resident-twins",
    title="Repair resident twins",
    prompt="repair",
    target_book_id=Some("wenyu-resident-twins"),
    cadence_ticks=60,
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-resident-twins-tick-20",
      book_id="wenyu-resident-twins",
      packet_id="packet-new",
      packet_path="new.json",
      run_id=Some("run-new"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Detached MoonClaw import completed for packet-new; inline run finished.\nkeeper_auto_triage: reconciled_from_watcher_ledger\nreconciled_watcher_decision: NeedsReview",
      output_contract="standing-watch",
      result_decision="NeedsReview",
      requires_review=true,
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [
      @moonbook.BookCatalogEntry::new(
        id="wenyu-resident-twins",
        name="Wenyu Resident Twins",
        purpose="Resident memory",
        workspace_root="/tmp/moontown-review-autonomous-repair/book",
      ),
    ],
    "/tmp/moontown-review-autonomous-repair/town.json",
    [goal],
  )
  let current = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-resident-twins-tick-20",
  ).unwrap()
  assert_eq(current.status, @core.TaskExecutionStatus::Completed)
  assert_eq(current.result_decision, "repair-still-open")
  assert_false(current.requires_review)
  assert_true(current.summary.contains("keeper_auto_triage: repair_still_open"))
}

///|
async test "generic standing watch review closes as no change" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let goal = @core.StandingGoal::new(
    id="watch-embodied-robotics",
    title="Watch embodied robotics",
    prompt="watch",
    target_book_id=Some("research-embodied-robotics"),
    cadence_ticks=60,
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-embodied-robotics-tick-18142",
      book_id="research-embodied-robotics",
      packet_id="packet-watch",
      packet_path="watch.json",
      run_id=Some("run-watch"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Detached MoonClaw import completed for packet-watch; inline run finished.\nkeeper_auto_triage: reconciled_from_watcher_ledger\nreconciled_watcher_decision: NeedsReview",
      output_contract="standing-watch",
      result_decision="NeedsReview",
      requires_review=true,
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [
      @moonbook.BookCatalogEntry::new(
        id="research-embodied-robotics",
        name="Research Embodied Robotics",
        purpose="Watch embodied robotics",
        workspace_root="/tmp/moontown-review-empty-watch/book",
      ),
    ],
    "/tmp/moontown-review-empty-watch/town.json",
    [goal],
  )
  let current = @core.find_execution(
    state, "standing-watch-embodied-robotics-tick-18142",
  ).unwrap()
  assert_eq(current.status, @core.TaskExecutionStatus::Completed)
  assert_eq(current.result_decision, "NoChange")
  assert_false(current.requires_review)
  assert_true(
    current.summary.contains("keeper_auto_triage: empty_completion_no_change"),
  )
  assert_true(current.summary.contains("standing_goal_decision: no_change"))
}

///|
async test "review queued standing watch closes when newer cycle is clean" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  let goal = @core.StandingGoal::new(
    id="book-quality-repair-wenyu-physical-bridge",
    title="Repair physical bridge",
    prompt="repair",
    target_book_id=Some("wenyu-physical-bridge"),
    cadence_ticks=60,
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-physical-bridge-tick-10",
      book_id="wenyu-physical-bridge",
      packet_id="packet-old",
      packet_path="old.json",
      run_id=Some("run-old"),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="older review",
      output_contract="standing-watch",
      result_decision="NeedsReview",
      requires_review=true,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-physical-bridge-tick-20",
      book_id="wenyu-physical-bridge",
      packet_id="packet-new",
      packet_path="new.json",
      run_id=Some("run-new"),
      status=@core.TaskExecutionStatus::Completed,
      summary="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nkeeper_auto_triage: accepted",
      output_contract="standing-watch",
      result_decision="NoChange",
      requires_review=false,
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [],
    "/tmp/moontown-review-clean-superseded/town.json",
    [goal],
  )
  let old = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-physical-bridge-tick-10",
  ).unwrap()
  let current = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-physical-bridge-tick-20",
  ).unwrap()
  assert_eq(old.status, @core.TaskExecutionStatus::Completed)
  assert_eq(old.result_decision, "superseded-review")
  assert_true(!old.requires_review)
  assert_eq(current.status, @core.TaskExecutionStatus::Completed)
  assert_eq(current.result_decision, "NoChange")
  assert_true(!current.requires_review)
}

///|
async test "superseded standing watch review is not reopened from ledger" {
  let root = "/tmp/moontown-superseded-review-ledger-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let goal = @core.StandingGoal::new(
    id="book-quality-repair-wenyu-physical-bridge",
    title="Repair physical bridge",
    prompt="repair",
    target_book_id=Some("wenyu-physical-bridge"),
    cadence_ticks=60,
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=10,
      target_book_id="wenyu-physical-bridge",
      decision=@core.WatcherDecisionKind::NeedsReview,
      detail="Detached MoonClaw import completed; inline run finished.",
      task_id=Some("standing-book-quality-repair-wenyu-physical-bridge-tick-10"),
      run_id=Some("run-old"),
      next_due_tick=70,
    ),
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-physical-bridge-tick-10",
      book_id="wenyu-physical-bridge",
      packet_id="packet-old",
      packet_path="old.json",
      run_id=Some("run-old"),
      status=@core.TaskExecutionStatus::Completed,
      summary="older review\nkeeper_auto_triage: superseded_review",
      output_contract="standing-watch",
      result_decision="superseded-review",
      requires_review=false,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-book-quality-repair-wenyu-physical-bridge-tick-20",
      book_id="wenyu-physical-bridge",
      packet_id="packet-new",
      packet_path="new.json",
      run_id=Some("run-new"),
      status=@core.TaskExecutionStatus::Completed,
      summary="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nkeeper_auto_triage: accepted",
      output_contract="standing-watch",
      result_decision="NoChange",
      requires_review=false,
    ),
  )
  reconcile_persisted_standing_watch_records(state, snapshot_path, [goal])
  let old = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-physical-bridge-tick-10",
  ).unwrap()
  assert_eq(old.status, @core.TaskExecutionStatus::Completed)
  assert_eq(old.result_decision, "superseded-review")
  assert_true(!old.requires_review)
  assert_true(old.summary.contains("superseded_review"))
  assert_false(old.summary.contains("reconciled_from_watcher_ledger"))
}
