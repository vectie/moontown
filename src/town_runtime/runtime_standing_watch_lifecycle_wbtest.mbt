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
test "standing watch infrastructure failure with stale review marker is not review" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-llm-training-tick-15819",
    book_id="research-llm",
    packet_id="packet",
    packet_path="packet.json",
    status=ReviewQueued,
    summary="Standing watch execution failed for research-llm. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals. standing_goal_decision: needs_review\ndelta_score: 0\nnew_source_count: 0",
    output_contract="test",
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    Failed,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-llm-training",
    tick=15819,
    target_book_id="research-llm",
    decision=NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail=execution.summary,
  )
  assert_eq(
    @standing_watch_policy.watcher_record_effective_decision(record),
    Failed,
  )
}

///|
test "standing watch transient failed record stays deferred accounting" {
  let record = @core.WatcherRunRecord::new(
    goal_id="book-quality-repair-research-opc",
    tick=18032,
    target_book_id="research-opc",
    decision=Failed,
    delta_score=0,
    new_source_count=0,
    detail="Standing watch execution failed for research-opc / standing-book-quality-repair-research-opc-tick-18032: timed out while importing MoonClaw proposal; no run id or detached import receipt became available before the heartbeat window.",
    task_id=Some("standing-book-quality-repair-research-opc-tick-18032"),
    next_due_tick=18047,
  )
  assert_eq(
    @standing_watch_policy.watcher_record_effective_decision(record),
    Deferred,
  )
}

///|
test "standing watch detached startup-log failure record stays deferred accounting" {
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=18122,
    target_book_id="research-opc",
    decision=Failed,
    delta_score=0,
    new_source_count=0,
    detail=(
      $|Detached MoonClaw import failed for keeper-research-opc-standing-watch-opc-news-tick-18122-422348240: {"level":"Info","pid":69142,"msg":"No model specified, auto-detecting...","tag":"Model"} | {"level":"Warn","pid":69142,"msg":"Directory '/Users/kq/.moonclaw/rules' does not exist, skipping.","tag":"job-analysis"} | {"level":"Info","pid":69142,"msg":"Loading skills from directory '/Users/kq/.moonclaw/skills/.system'...","tag":"job-analysis"}
    ),
    task_id=Some("standing-watch-opc-news-tick-18122"),
    next_due_tick=18137,
  )
  assert_eq(
    @standing_watch_policy.watcher_record_effective_decision(record),
    Deferred,
  )
  let summary = @runtime_status.watcher_status_summary([record], [])
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
    status=Completed,
    summary~,
    output_contract="standing-watch-live-snapshot",
    requires_review=true,
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    Deferred,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-robotics",
    tick=10,
    target_book_id="research-robotics",
    decision=NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail=summary,
  )
  assert_eq(
    @standing_watch_policy.watcher_record_effective_decision(record),
    Deferred,
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
