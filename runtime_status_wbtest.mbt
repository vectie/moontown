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
