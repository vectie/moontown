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
test "standing watch ids are compact and stable" {
  assert_eq(standing_watch_task_kind(), "standing-watch")
  assert_true(standing_watch_task_kind_matches(standing_watch_task_kind()))
  assert_false(standing_watch_task_kind_matches("watch"))
  assert_eq(
    standing_watch_task_id("Book Quality Repair: Research OPC", 42),
    "standing-book-quality-repair-research-opc-tick-42",
  )
  assert_eq(compact_watch_segment("$$$"), "standing-goal")
  assert_eq(
    standing_watch_task_tick_prefix("Book Quality Repair: Research OPC"),
    "standing-book-quality-repair-research-opc-tick-",
  )
}

///|
test "standing watch ids parse back to matching goal ticks" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Track latest OPC signals.",
  )
  assert_true(
    standing_watch_tick_for_goal_task(goal, "standing-watch-opc-news-tick-1440")
    is Some(1440),
  )
  assert_true(
    standing_watch_tick_for_goal_task(goal, "standing-other-tick-1440") is None,
  )
  assert_true(
    standing_goal_for_execution_task(
      [goal],
      "standing-watch-opc-news-tick-1440",
    )
    is Some(_),
  )
}

///|
test "standing watch marker parser owns emitted contract fields" {
  let summary =
    #|standing_goal_decision: update
    #|delta_score: 17
    #|new_source_count=3
    #|book_changed: yes
  assert_true(
    standing_watch_marker_decision(summary.to_lower()) is Some(Update),
  )
  assert_eq(standing_watch_marker_int(summary, "delta_score", fallback=0), 17)
  assert_eq(
    standing_watch_marker_int(summary, "new_source_count", fallback=0),
    3,
  )
  assert_true(
    standing_watch_marker_value(summary, "book_changed") is Some("yes"),
  )
  assert_true(!standing_watch_summary_has_zero_material_delta(summary))
}

///|
test "watcher record execution matching uses concrete run id when present" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-tick-1",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Completed,
    summary="standing_goal_decision: update",
    output_contract="standing-watch-live-snapshot",
    run_id=Some("run-1"),
  )
  let matching = @core.WatcherRunRecord::new(
    goal_id="watch-opc",
    tick=1,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Update,
    task_id=Some("standing-watch-opc-tick-1"),
    run_id=Some("run-1"),
  )
  let stale = @core.WatcherRunRecord::new(
    goal_id="watch-opc",
    tick=1,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Update,
    task_id=Some("standing-watch-opc-tick-1"),
    run_id=Some("run-old"),
  )
  assert_true(watcher_record_matches_execution(matching, execution))
  assert_true(!watcher_record_matches_execution(stale, execution))
}

///|
test "terminal watcher decision maps to execution status" {
  assert_eq(
    task_status_for_terminal_watcher_decision(
      @core.WatcherDecisionKind::NeedsReview,
    ),
    @core.TaskExecutionStatus::ReviewQueued,
  )
  assert_eq(
    task_status_for_terminal_watcher_decision(@core.WatcherDecisionKind::Failed),
    @core.TaskExecutionStatus::Failed,
  )
  assert_eq(
    task_status_for_terminal_watcher_decision(@core.WatcherDecisionKind::Update),
    @core.TaskExecutionStatus::Completed,
  )
  assert_eq(
    task_status_for_terminal_watcher_decision(
      @core.WatcherDecisionKind::NoChange,
    ),
    @core.TaskExecutionStatus::Completed,
  )
}

///|
test "standing watch event shape comes from policy" {
  let event = standing_watch_event_for_record(
    @core.WatcherRunRecord::new(
      goal_id="watch-opc",
      tick=7,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Update,
      detail="standing_goal_decision: update",
      task_id=Some("standing-watch-opc-tick-7"),
      run_id=Some("run-7"),
      next_due_tick=37,
    ),
  )
  assert_eq(event.id, "event-watch-7-watch-opc")
  assert_eq(event.kind, "standing-watch")
  assert_true(event.detail.contains("watch-opc -> Update"))
  assert_true(event.related_book_id == Some("research-opc"))
  assert_true(event.related_task_id == Some("standing-watch-opc-tick-7"))
  assert_true(event.related_run_id == Some("run-7"))
}

///|
test "standing watch transient dispatch and stale window policy are centralized" {
  let detail = "Standing watch execution failed. RUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\nSystemStore::save_job_proposals"
  assert_true(standing_watch_transient_dispatch_error(detail))
  assert_eq(standing_watch_stale_window_ticks(), 120)
}

///|
test "empty completion no-change summary keeps accounting contract stable" {
  let summary = standing_watch_empty_completion_no_change_summary("watch-task")
  let lines = summary.split("\n").to_array()
  assert_eq(lines.length(), 12)
  assert_eq(lines[0], "standing_goal_decision: no_change")
  assert_eq(lines[1], "delta_score: 0")
  assert_eq(lines[2], "new_source_count: 0")
  assert_eq(lines[10], "book_watch_record_id: watch-task")
  assert_true(lines[11].contains("mayor classified it as no_change"))
}

///|
test "empty review completion summary reuses strict no-change accounting" {
  let observed = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-tick-7",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="Workflow completed without a decision marker.",
    output_contract="standing-watch-live-snapshot",
    requires_review=true,
    notify_town=true,
  )
  let summary = standing_watch_empty_review_completion_summary(observed)
  assert_true(
    summary.contains("keeper_auto_triage: empty_completion_no_change"),
  )
  assert_true(summary.contains("keeper_auto_triage_reason: watcher completed"))
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("checked_sources_count: 0"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(
    summary.contains("book_watch_record_id: standing-watch-opc-tick-7"),
  )
}
