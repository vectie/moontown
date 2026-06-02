///|
test "runtime status summarizes execution lifecycle counts" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-running",
      book_id="research-moontown",
      packet_id="packet-running",
      packet_path="packet-running.json",
      status=@core.TaskExecutionStatus::Running,
      summary="running",
      output_contract="test",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-review",
      book_id="research-moonbook",
      packet_id="packet-review",
      packet_path="packet-review.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="review",
      output_contract="test",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 1)
  assert_eq(status.review_count, 1)
  assert_eq(status.execution_count, 2)
  assert_eq(status.standing_goal_count, 0)
}

///|
test "runtime status ignores stale duplicate running record for terminal task" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-dup",
      book_id="research-opc",
      packet_id="packet-final",
      packet_path="packet-final.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="terminal",
      output_contract="test",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-dup",
      book_id="research-opc",
      packet_id="packet-running",
      packet_path="packet-running.json",
      status=@core.TaskExecutionStatus::Running,
      summary="old live snapshot",
      output_contract="test",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 0)
  assert_eq(status.review_count, 1)
}

///|
test "runtime status includes due standing goal actions" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Research OPC.",
    target_book_id=Some("research-opc"),
    next_due_tick=1,
  )
  let status = runtime_status_from_state(
    state,
    "/tmp/town.json",
    standing_goals=[goal],
    daemon_tick=0,
  )
  assert_eq(status.standing_goal_count, 1)
  assert_eq(status.due_standing_goal_count, 1)
  assert_true(
    status.daemon_actions.any(fn(action) { action.kind == "standing-goal-due" }),
  )
}

///|
async test "budget deferred standing goals stay due and are not marked run" {
  let root = "/tmp/moontown-standing-budget-deferral-check"
  ignore_checked_command("rm", ["-rf", root])
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  let launched = @core.StandingGoal::new(
    id="watch-first",
    title="First due watch",
    prompt="first",
    target_book_id=Some("missing-first"),
    cadence_ticks=60,
    next_due_tick=10,
  )
  let deferred = @core.StandingGoal::new(
    id="watch-second",
    title="Second due watch",
    prompt="second",
    target_book_id=Some("missing-second"),
    cadence_ticks=60,
    next_due_tick=10,
  )
  let updated = dispatch_due_standing_goals(
    state,
    @roles.Mayor::new(),
    [],
    [launched, deferred],
    10,
    "\{root}/town.json",
  )
  let first = find_runtime_standing_goal_by_id(updated, "watch-first").unwrap()
  let second = find_runtime_standing_goal_by_id(updated, "watch-second").unwrap()
  assert_true(first.last_run_tick is Some(10))
  assert_eq(first.next_due_tick, 25)
  assert_true(second.last_run_tick is None)
  assert_eq(second.next_due_tick, 10)
  assert_true(
    state.events.any(fn(event) {
      event.id == "event-standing-goal-10-watch-second-deferred-budget"
    }),
  )
}

///|
async test "budget deferred standing goal state self repairs without watcher record" {
  let root = "/tmp/moontown-standing-budget-repair-check"
  ignore_checked_command("rm", ["-rf", root])
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-standing-goal-10-watch-second-deferred-budget",
      kind="standing-goal",
      detail="budget deferred",
    ),
  )
  let corrupted = @core.StandingGoal::new(
    id="watch-second",
    title="Second due watch",
    prompt="second",
    target_book_id=Some("missing-second"),
    cadence_ticks=60,
    next_due_tick=70,
    last_run_tick=Some(10),
  )
  let repaired = reconcile_budget_deferred_standing_goal_state(
    state,
    [corrupted],
    "\{root}/town.json",
  )
  let goal = find_runtime_standing_goal_by_id(repaired, "watch-second").unwrap()
  assert_true(goal.last_run_tick is None)
  assert_eq(goal.next_due_tick, 10)
  assert_true(
    state.events.any(fn(event) {
      event.id == "event-standing-goal-10-watch-second-budget-state-repaired"
    }),
  )
}

///|
async test "cap deferred standing goals stay due and are not marked run" {
  let root = "/tmp/moontown-standing-cap-deferral-check"
  ignore_checked_command("rm", ["-rf", root])
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  for index in 0..<max_live_external_executions() {
    state.register_execution(
      @core.TaskExecutionRecord::new(
        task_id="live-external-\{index}",
        book_id="research-opc",
        packet_id="packet-\{index}",
        packet_path="packet-\{index}.json",
        run_id=Some("run-\{index}"),
        status=@core.TaskExecutionStatus::Running,
        summary="running",
        output_contract="test",
      ),
    )
  }
  let goal = @core.StandingGoal::new(
    id="watch-cap",
    title="Cap due watch",
    prompt="cap",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    next_due_tick=10,
  )
  let updated = dispatch_due_standing_goals(
    state,
    @roles.Mayor::new(),
    [],
    [goal],
    10,
    "\{root}/town.json",
  )
  let kept = find_runtime_standing_goal_by_id(updated, "watch-cap").unwrap()
  assert_true(kept.last_run_tick is None)
  assert_eq(kept.next_due_tick, 10)
  assert_true(
    state.events.any(fn(event) {
      event.id == "event-standing-goal-10-watch-cap-deferred-cap"
    }),
  )
}

///|
test "runtime status includes watcher ledger summary" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=3,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    detail="no useful delta",
    next_due_tick=15,
  )
  let status = runtime_status_from_state(state, "/tmp/town.json", watcher_records=[
    record,
  ])
  assert_eq(status.watcher_record_count, 1)
  assert_true(status.watcher_summary.contains("NoChange"))
  assert_true(status.summary.contains("watcher_records=1"))
}

///|
test "runtime status includes book template request inbox summary" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  let status = runtime_status_from_state(
    state,
    "/tmp/town.json",
    book_template_request_status=Some({
      request_path: "/tmp/book-template-requests.json",
      event_path: "/tmp/book-template-request-events.jsonl",
      request_count: 3,
      pending_count: 1,
      installed_count: 1,
      failed_count: 1,
      retry_count: 1,
      ready: false,
      summary: "book_template_requests=3 pending=1 retry=1 installed=1 failed=1",
      latest_event_summary: "failed: `request-3` tick=8",
    }),
  )
  assert_eq(status.book_template_request_count, 3)
  assert_eq(status.pending_book_template_request_count, 2)
  assert_eq(status.failed_book_template_request_count, 1)
  assert_eq(status.enabled_standing_goal_count, 0)
  assert_eq(status.disabled_standing_goal_count, 0)
  assert_eq(
    status.book_template_latest_event_summary,
    "failed: `request-3` tick=8",
  )
  assert_true(status.summary.contains("book_template_requests=3"))
  assert_true(status.summary.contains("pending_template_requests=2"))
}

///|
test "runtime status distinguishes historical and current watcher due ticks" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=3,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Deferred,
    detail="previous run active",
    next_due_tick=4,
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="Track OPC.",
    target_book_id=Some("research-opc"),
    next_due_tick=64,
  )
  let status = runtime_status_from_state(
    state,
    "/tmp/town.json",
    standing_goals=[goal],
    watcher_records=[record],
  )
  assert_true(status.watcher_summary.contains("recorded_next_due_tick=4"))
  assert_true(status.watcher_summary.contains("current_next_due_tick=64"))
}

///|
test "daemon tick floor uses observed watcher and standing goal time" {
  let records = [
    @core.WatcherRunRecord::new(
      goal_id="watch-opc-news",
      tick=15877,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      next_due_tick=15907,
    ),
  ]
  let goals = [
    @core.StandingGoal::new(
      id="watch-opc-news",
      title="Track OPC",
      prompt="track",
      target_book_id=Some("research-opc"),
      next_due_tick=15908,
      last_run_tick=Some(15888),
    ),
  ]
  assert_eq(latest_watcher_record_tick(records), 15877)
  assert_eq(latest_standing_goal_tick(goals), 15888)
}

///|
test "watcher status prefers parsed terminal record over generic duplicate" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="track",
    target_book_id=Some("research-opc"),
    next_due_tick=18032,
  )
  let parsed = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=17972,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    delta_score=8,
    new_source_count=0,
    detail="standing_goal_decision: no_change\ndelta_score: 8\nnew_source_count: 0\nbook_changed: no",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18032,
  )
  let generic = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=17972,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail="MoonClaw run run-opc completed: Workflow completed",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18002,
  )
  let summary = watcher_status_summary([parsed, generic], [goal])
  assert_true(summary.contains("latest=watch-opc-news/NoChange"))
  assert_true(!summary.contains("NeedsReview"))
}

///|
test "daemon tick floor includes execution task tick" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-15949",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Running,
      summary="running",
      output_contract="standing-watch",
    ),
  )
  assert_eq(tick_from_task_id("standing-watch-opc-news-tick-15949"), 15949)
  assert_eq(latest_execution_task_tick(state), 15949)
}

///|
async test "daemon tick floor parses latest daemon log sequence" {
  let root = "/tmp/moontown-daemon-log-sequence-test"
  ignore_checked_command("rm", ["-rf", root])
  let log_path = "\{root}/daemon.log"
  write_text_file(
    log_path, "[1780279335798] tick phase=standing-goals sequence=15888\n[1780279400000] tick phase=done sequence=15890\n",
  )
  assert_eq(latest_daemon_log_sequence(log_path), 15890)
}

///|
async test "runtime status effective tick includes active execution task tick" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-15951",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Running,
      summary="running",
      output_contract="standing-watch",
    ),
  )
  let daemon = @scheduler.DaemonState::new(tick_sequence=15900)
  let tick = effective_daemon_tick(
    "/tmp/moontown-status-tick-test/town.json",
    daemon,
    state,
    [],
    [],
  )
  assert_eq(tick, 15951)
}

///|
test "runtime status suppresses superseded standing watch failures" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="Research OPC",
      purpose="Watch OPC",
      workspace_root="/tmp/research-opc",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-2",
      book_id="research-opc",
      packet_id="packet-2",
      packet_path="packet-2.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="no eligible worker",
      output_contract="test",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-5",
      book_id="research-opc",
      packet_id="packet-5",
      packet_path="packet-5.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="standing_goal_decision: no_change",
      output_contract="test",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.failed_count, 0)
  assert_eq(status.daemon_actions.length(), 0)
}

///|
test "standing watch decision reads MoonBook no-change marker" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Completed,
    summary="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0",
    output_contract="test",
  )
  assert_eq(
    standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::NoChange,
  )
  assert_eq(standing_watch_delta_score(execution), 0)
  assert_eq(standing_watch_new_source_count(execution), 0)
}

///|
test "standing watch decision treats missing marker as review instead of update" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Completed,
    summary="Workflow completed workspace=/tmp/book",
    output_contract="test",
  )
  assert_eq(
    standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::NeedsReview,
  )
  assert_eq(standing_watch_delta_score(execution), 0)
  assert_eq(standing_watch_new_source_count(execution), 0)
}

///|
test "standing watch decision honors marker even when execution is review queued" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="standing_goal_decision: no_change\ndelta_score: 9\nnew_source_count: 0\nnext_check_hint: slower",
    output_contract="test",
  )
  assert_eq(
    standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::NoChange,
  )
  assert_eq(standing_watch_delta_score(execution), 9)
}

///|
test "standing watch transient dispatch marker defers immediate retry" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Completed,
    summary="Resource temporarily unavailable\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true",
    output_contract="test",
  )
  assert_eq(
    standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::Deferred,
  )
}

///|
test "standing watch classifies MoonClaw proposal store abort as transient" {
  let detail = "Standing watch execution failed. RUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\n/vectie/moonclaw/job/system_storage.mbt:886 by SystemStore::save_job_proposals"
  assert_eq(standing_watch_transient_dispatch_error(detail), true)
}

///|
test "standing watch transient infrastructure review is stabilized as deferred accounting" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-15951",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="Standing watch execution failed for research-opc. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals.\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true",
    output_contract="standing-watch-live-snapshot",
    requires_review=true,
    notify_town=true,
  )
  let stabilized = stabilize_deferred_standing_watch_execution(execution, 15951)
  assert_eq(stabilized.status, @core.TaskExecutionStatus::Completed)
  assert_eq(stabilized.result_decision, "deferred")
  assert_eq(stabilized.requires_review, false)
  assert_eq(stabilized.notify_town, false)
}

///|
test "standing watch running snapshot uses daemon tick heartbeat window" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="Research OPC",
    purpose="Track OPC",
    workspace_root="/tmp/research-opc",
  )
  let task = @moonbook.BookTask::new(
    id="standing-watch-opc-news-tick-16073",
    title="Standing watch",
    kind="standing-watch",
    prompt="Watch OPC",
    priority=95,
    requires_review=false,
  )
  let execution = running_standing_watch_execution(
    entry, task, "claw-research-opc-watcher", 16073,
  )
  assert_eq(execution.heartbeat_tick, 16073)
  assert_eq(execution.stale_after_tick, 16193)
}

///|
test "legacy standing watch stale record detects mixed tick domains" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-16134",
    book_id="research-opc",
    packet_id="pending-research-opc-standing-watch-opc-news-tick-16134",
    packet_path="",
    status=@core.TaskExecutionStatus::Stale,
    summary="Execution standing-watch-opc-news-tick-16134 missed its heartbeat window and needs mayor recovery.",
    output_contract="standing-watch-live-snapshot",
    heartbeat_tick=2155,
    stale_after_tick=2185,
  )
  assert_eq(legacy_tick_domain_stale_standing_watch(execution), true)
}

///|
test "legacy review queued standing watch infrastructure failure is retry accounting" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-llm-training-tick-16265",
    book_id="research-llm",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="Mayor retry failed. Standing watch execution failed for research-llm. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals.\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: false",
    output_contract="keeper.plan.packet.v1",
    heartbeat_tick=3346,
    stale_after_tick=3,
    requires_review=false,
    notify_town=true,
  )
  assert_eq(
    legacy_review_queued_retry_accounting_standing_watch(execution),
    true,
  )
}

///|
test "standing watch infrastructure failure with stale review marker is not review" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-llm-training-tick-15819",
    book_id="research-llm",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="Standing watch execution failed for research-llm. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals. standing_goal_decision: needs_review\ndelta_score: 0\nnew_source_count: 0",
    output_contract="test",
  )
  assert_eq(
    standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::Failed,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-llm-training",
    tick=15819,
    target_book_id="research-llm",
    decision=@core.WatcherDecisionKind::NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail=execution.summary,
  )
  assert_eq(
    watcher_record_effective_decision(record),
    @core.WatcherDecisionKind::Failed,
  )
}

///|
test "standing watch transient failed record stays deferred accounting" {
  let record = @core.WatcherRunRecord::new(
    goal_id="book-quality-repair-research-opc",
    tick=18032,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Failed,
    delta_score=0,
    new_source_count=0,
    detail="Standing watch execution failed for research-opc / standing-book-quality-repair-research-opc-tick-18032: timed out while importing MoonClaw proposal; no run id or detached import receipt became available before the heartbeat window.",
    task_id=Some("standing-book-quality-repair-research-opc-tick-18032"),
    next_due_tick=18047,
  )
  assert_eq(
    watcher_record_effective_decision(record),
    @core.WatcherDecisionKind::Deferred,
  )
}

///|
test "standing watch detached startup-log failure record stays deferred accounting" {
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=18122,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Failed,
    delta_score=0,
    new_source_count=0,
    detail=(
      $|Detached MoonClaw import failed for keeper-research-opc-standing-watch-opc-news-tick-18122-422348240: {"level":"Info","pid":69142,"msg":"No model specified, auto-detecting...","tag":"Model"} | {"level":"Warn","pid":69142,"msg":"Directory '/Users/kq/.moonclaw/rules' does not exist, skipping.","tag":"job-analysis"} | {"level":"Info","pid":69142,"msg":"Loading skills from directory '/Users/kq/.moonclaw/skills/.system'...","tag":"job-analysis"}
    ),
    task_id=Some("standing-watch-opc-news-tick-18122"),
    next_due_tick=18137,
  )
  assert_eq(
    watcher_record_effective_decision(record),
    @core.WatcherDecisionKind::Deferred,
  )
  let summary = watcher_status_summary([record], [])
  assert_true(summary.contains("latest=watch-opc-news/Deferred"))
  assert_true(!summary.contains("Failed"))
}

///|
test "standing watch persisted orphaned running recovery stays deferred" {
  let summary = "MoonClaw run run-1 is indexed as Running, but no live proposal process was found; treating it as failed for mayor recovery.\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: false\npersisted_evidence_id: EV-test\nkeeper_auto_triage: persisted_non_review_result"
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-robotics-tick-10",
    book_id="research-robotics",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Completed,
    summary~,
    output_contract="standing-watch-live-snapshot",
    requires_review=true,
  )
  assert_eq(
    standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::Deferred,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-robotics",
    tick=10,
    target_book_id="research-robotics",
    decision=@core.WatcherDecisionKind::NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail=summary,
  )
  assert_eq(
    watcher_record_effective_decision(record),
    @core.WatcherDecisionKind::Deferred,
  )
}

///|
test "standing watch live snapshot is topic agnostic" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-euv-lithography",
    name="Research EUV Lithography",
    purpose="Watch EUV lithography research",
    workspace_root="/tmp/research-euv-lithography",
  )
  let task = @moonbook.BookTask::new(
    id="standing-watch-euv-lithography-tick-1",
    title="Standing watch: Track EUV lithography",
    kind="standing-watch",
    prompt="Track EUV lithography updates.",
    priority=95,
    requires_review=false,
  )
  let execution = running_standing_watch_execution(entry, task, "watcher", 7)
  assert_true(execution.summary.contains("Track EUV lithography"))
  assert_true(execution.summary.contains("research-euv-lithography"))
  assert_true(!execution.summary.contains("OPC"))
}

///|
test "standing watch history parser reads provider decision for current task" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### standing-watch-opc-news-tick-4
    $|
    $|- Decision: `unknown`
    $|- Delta score: `unknown`
    $|- New source count: `unknown`
    $|- Next check hint: `normal`
    $|- Summary: MoonClaw run completed
    $|
    $|### provider-standing-watch-123
    $|
    $|- Decision: `no_change`
    $|- Delta score: `9`
    $|- New source count: `0`
    $|- Next check hint: `slower`
    $|- Checked sources count: `5`
    $|- New sources found: `2`
    $|- Accepted facts count: `0`
    $|- Rejected facts count: `2`
    $|- Wiki pages changed count: `0`
    $|- Book changed: `no`
    $|- Summary: standing_goal_decision: no_change
    $|
    $|### standing-watch-opc-news-tick-3
    $|
    $|- Decision: `unknown`
  let summary = standing_watch_history_decision_summary_for_task(
    history, "standing-watch-opc-news-tick-4",
  ).unwrap()
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("delta_score: 9"))
  assert_true(summary.contains("checked_sources_count: 5"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("wiki_pages_changed_count: 0"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(
    summary.contains("book_watch_record_id: provider-standing-watch-123"),
  )
}

///|
test "standing watch history parser reads newest provider decision before task block exists" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### provider-standing-watch-456
    $|
    $|- Decision: `no_change`
    $|- Delta score: `5`
    $|- New source count: `0`
    $|- Next check hint: `slower`
    $|- Checked sources count: `7`
    $|- Rejected facts count: `3`
    $|- Summary: standing_goal_decision: no_change
    $|checked_sources_count: 7
    $|rejected_facts_count: 3
    $|book_changed: no
    $|
    $|### standing-watch-opc-news-tick-4
    $|
    $|- Decision: `unknown`
  let summary = standing_watch_latest_provider_decision_summary(history).unwrap()
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("delta_score: 5"))
  assert_true(summary.contains("checked_sources_count: 7"))
  assert_true(summary.contains("rejected_facts_count: 3"))
  assert_true(
    summary.contains("book_watch_record_id: provider-standing-watch-456"),
  )
}

///|
test "standing watch collapse removes folded provider decision block" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### standing-watch-opc-news-tick-5
    $|
    $|- Decision: `no_change`
    $|- Summary: standing_goal_decision: no_change
    $|book_watch_record_id: provider-standing-watch-456
    $|
    $|### provider-standing-watch-456
    $|
    $|- Decision: `no_change`
    $|- Summary: standing_goal_decision: no_change
    $|
    $|### standing-watch-opc-news-tick-4
    $|
    $|- Decision: `unknown`
  let collapsed = remove_standing_watch_history_block(
    history, "provider-standing-watch-456",
  )
  assert_true(collapsed.contains("### standing-watch-opc-news-tick-5"))
  assert_true(!collapsed.contains("### provider-standing-watch-456"))
  assert_true(collapsed.contains("### standing-watch-opc-news-tick-4"))
}

///|
test "standing watch history parser reads accounting markers from summary body" {
  let history =
    $|# Standing Watch
    $|
    $|## Decisions
    $|
    $|### standing-watch-opc-news-tick-3870
    $|
    $|- Decision: `unknown`
    $|- Delta score: `unknown`
    $|- New source count: `unknown`
    $|- Next check hint: `normal`
    $|- Summary: MoonClaw run completed
    $|
    $|### provider-standing-watch-2063512028-624320892
    $|
    $|- Decision: `no_change`
    $|- Delta score: `10`
    $|- New source count: `0`
    $|- Next check hint: `slower`
    $|- Summary: standing_goal_decision: no_change
    $|delta_score: 10
    $|new_source_count: 0
    $|next_check_hint: slower
    $|checked_sources_count: 4
    $|new_sources_found: 1
    $|accepted_facts_count: 0
    $|rejected_facts_count: 1
    $|wiki_pages_changed_count: 0
    $|book_changed: no
    $|Re-checked baseline sources and rejected one inaccessible candidate.
    $|
    $|### standing-watch-opc-news-tick-3795
    $|
    $|- Decision: `unknown`
  let summary = standing_watch_history_decision_summary_for_task(
    history, "standing-watch-opc-news-tick-3870",
  ).unwrap()
  assert_true(summary.contains("checked_sources_count: 4"))
  assert_true(summary.contains("new_sources_found: 1"))
  assert_true(summary.contains("rejected_facts_count: 1"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(summary.contains("Re-checked baseline sources"))
}

///|
test "standing watch prompt requires strict research accounting" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Track latest OPC signals with judgement.",
    target_book_id=Some("research-opc"),
  )
  let prompt = standing_watch_prompt(goal, "research-opc", 12, 2)
  assert_true(prompt.contains("Research temperament"))
  assert_true(prompt.contains("Use imagination"))
  assert_true(prompt.contains("checked_sources_count"))
  assert_true(prompt.contains("accepted_facts_count"))
  assert_true(prompt.contains("wiki_pages_changed_count"))
  assert_true(prompt.contains("book_changed: yes | no"))
  assert_true(prompt.contains("failed and ordinary no_change cycles"))
}

///|
test "book quality repair prompt requires active gap closure" {
  let goal = @core.StandingGoal::new(
    id="book-quality-repair-research-embodied-robotics",
    title="Repair embodied robotics book",
    prompt="Run a source-screening and synthesis pass that creates missing artifacts.",
    target_book_id=Some("research-embodied-robotics"),
  )
  let prompt = standing_watch_prompt(
    goal, "research-embodied-robotics", 18084, 3,
  )
  assert_true(prompt.contains("Book-quality repair mode"))
  assert_true(prompt.contains("wiki/reviews/book-quality-repair.md"))
  assert_true(prompt.contains("Do not return ordinary `no_change`"))
  assert_true(
    prompt.contains("while the repair queue still names missing artifacts"),
  )
  assert_true(prompt.contains("Return `update` when durable book artifacts"))
}

///|
test "research readiness exposes typed coverage gaps" {
  let summary = @moonbook.BookStateSummary::new(
    book_id="research-moonclaw",
    root="/tmp/research-moonclaw",
    page_count=2,
    source_count=0,
    entity_count=0,
    concept_count=0,
    pending_review_count=0,
    keeper_memory_count=0,
    keeper_working_count=0,
    evidence_count=0,
    summary="empty",
  )
  let readiness = ResearchReadiness::from_summary(summary)
  assert_true(!readiness.substantive_coverage_ready)
  assert_true(readiness.gaps.length() >= 4)
}

///|
test "research readiness reports pending review without treating it as coverage gap" {
  let summary = @moonbook.BookStateSummary::new(
    book_id="research-llm-training",
    root="/tmp/research-llm-training",
    page_count=8,
    source_count=2,
    source_page_count=2,
    verified_source_count=2,
    entity_count=1,
    entity_page_count=1,
    concept_count=1,
    concept_page_count=1,
    pending_review_count=1,
    keeper_memory_count=0,
    keeper_working_count=0,
    evidence_count=3,
    summary="ready with human review backlog",
  )
  let readiness = ResearchReadiness::from_summary(summary)
  assert_true(readiness.substantive_coverage_ready)
  assert_eq(readiness.pending_review_count, 1)
  assert_true(readiness.gaps.is_empty())
}

///|
test "standing goal save merge preserves externally added repair goals" {
  let existing = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch",
    target_book_id=Some("research-opc"),
    next_due_tick=10,
  )
  let external_repair = @core.StandingGoal::new(
    id="book-quality-repair-research-opc",
    title="Repair OPC",
    prompt="repair",
    target_book_id=Some("research-opc"),
    next_due_tick=11,
  )
  let updated_existing = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch",
    target_book_id=Some("research-opc"),
    next_due_tick=70,
    last_run_tick=Some(10),
  )
  let merged = merge_standing_goal_updates([existing, external_repair], [
    updated_existing,
  ])
  assert_eq(merged.length(), 2)
  assert_eq(merged[0].id, "watch-opc-news")
  assert_eq(merged[0].next_due_tick, 70)
  assert_eq(merged[1].id, "book-quality-repair-research-opc")
  assert_eq(merged[1].next_due_tick, 11)
}

///|
test "standing goal dispatch budget is intentionally bounded" {
  assert_eq(max_standing_goal_dispatches_per_tick(), 1)
  assert_eq(standing_goal_dispatch_index(0, 4, 5), 1)
  assert_eq(standing_goal_dispatch_index(3, 4, 5), 0)
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    next_due_tick=10,
  )
  let deferred = goal.mark_watcher_decision(
    100,
    @core.WatcherDecisionKind::Deferred,
  )
  assert_true(deferred.next_due_tick > 100)
  assert_eq(deferred.next_due_tick, 160)
}
