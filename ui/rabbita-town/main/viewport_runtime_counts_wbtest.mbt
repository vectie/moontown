///|
fn runtime_count_test_worker(status : @core.WorkerStatus) -> WorkerSim {
  {
    id: "worker-\{status.to_string()}",
    title: "Runtime Worker",
    role: "test",
    book_id: "book",
    status,
    zone_key: "book-test",
    energy: 80,
    load: 20,
    summary: "test worker",
  }
}

///|
fn runtime_count_test_worker_with_role(
  status : @core.WorkerStatus,
  role : String,
) -> WorkerSim {
  {
    id: "worker-\{status.to_string()}-\{role}",
    title: "Runtime Worker",
    role: role,
    book_id: "book",
    status: status,
    zone_key: "book-test",
    energy: 80,
    load: 20,
    summary: "test worker",
  }
}

///|
fn runtime_count_test_execution(
  status : @core.TaskExecutionStatus,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id="task-\{status.to_string()}",
    book_id="book",
    packet_id="packet-\{status.to_string()}",
    packet_path="packet.json",
    status~,
    summary="test execution",
    output_contract="contract",
  )
}

///|
test "worker feed kind classifies blocked watcher and quiet workers" {
  assert_true(
    worker_feed_kind(runtime_count_test_worker(@core.WorkerStatus::Blocked)) is
      BlockedWorker,
  )
  assert_true(
    worker_feed_kind(
      runtime_count_test_worker_with_role(
        @core.WorkerStatus::Idle,
        "Standing Watcher",
      ),
    ) is OnDutyWatcher,
  )
  assert_true(
    worker_feed_kind(runtime_count_test_worker(@core.WorkerStatus::Idle)) is
      QuietWorker,
  )
  assert_true(
    worker_feed_kind(
      runtime_count_test_worker_with_role(
        @core.WorkerStatus::Running,
        "Standing Watcher",
      ),
    ) is QuietWorker,
  )
}

///|
test "worker feed item centralizes worker alert and watcher mapping" {
  let blocked = worker_feed_item(
    runtime_count_test_worker(@core.WorkerStatus::Blocked),
    "watcher idle",
  )
  assert_eq(blocked.unwrap().tone, "alert")
  assert_true(blocked.unwrap().title.contains("stalled"))
  assert_true(blocked.unwrap().detail.contains("Mayor should recover"))
  let watcher = worker_feed_item(
    runtime_count_test_worker_with_role(
      @core.WorkerStatus::Idle,
      "Standing Watcher",
    ),
    "next check waits for real time",
  )
  assert_eq(watcher.unwrap().tone, "calm")
  assert_true(watcher.unwrap().title.contains("is on duty"))
  assert_eq(watcher.unwrap().detail, "next check waits for real time")
  assert_true(
    worker_feed_item(
      runtime_count_test_worker(@core.WorkerStatus::Idle),
      "watcher idle",
    ) is None,
  )
  assert_true(
    worker_feed_item(
      runtime_count_test_worker_with_role(
        @core.WorkerStatus::Running,
        "Standing Watcher",
      ),
      "watcher idle",
    ) is None,
  )
}

///|
test "push worker alert messages delegates item projection" {
  let feed : Array[FeedItem] = []
  push_worker_alert_messages(
    feed,
    [
      runtime_count_test_worker(@core.WorkerStatus::Blocked),
      runtime_count_test_worker_with_role(
        @core.WorkerStatus::Idle,
        "Standing Watcher",
      ),
      runtime_count_test_worker(@core.WorkerStatus::Running),
    ],
    "watcher waiting for next real-world tick",
  )
  assert_eq(feed.length(), 2)
  assert_eq(feed[0].tone, "alert")
  assert_eq(feed[1].tone, "calm")
  assert_eq(feed[1].detail, "watcher waiting for next real-world tick")
}

///|
test "worker feed items projects visible worker messages only" {
  let items = worker_feed_items(
    [
      runtime_count_test_worker(@core.WorkerStatus::Blocked),
      runtime_count_test_worker_with_role(
        @core.WorkerStatus::Idle,
        "Standing Watcher",
      ),
      runtime_count_test_worker(@core.WorkerStatus::Running),
    ],
    "watcher waiting for next real-world tick",
  )
  assert_eq(items.length(), 2)
  assert_eq(items[0].tone, "alert")
  assert_true(items[0].title.contains("stalled"))
  assert_eq(items[1].tone, "calm")
  assert_eq(items[1].detail, "watcher waiting for next real-world tick")
}

///|
test "execution count summary centralizes stage counts" {
  let summary = execution_count_summary([
    runtime_count_test_execution(@core.TaskExecutionStatus::PacketReady),
    runtime_count_test_execution(@core.TaskExecutionStatus::ProposalImported),
    runtime_count_test_execution(@core.TaskExecutionStatus::RunConfirmed),
    runtime_count_test_execution(@core.TaskExecutionStatus::Running),
    runtime_count_test_execution(@core.TaskExecutionStatus::AwaitingPersistence),
    runtime_count_test_execution(@core.TaskExecutionStatus::ReviewQueued),
    runtime_count_test_execution(@core.TaskExecutionStatus::Completed),
    runtime_count_test_execution(@core.TaskExecutionStatus::Stale),
    runtime_count_test_execution(@core.TaskExecutionStatus::Failed),
  ])
  assert_eq(summary.total, 9)
  assert_eq(summary.packet_ready, 1)
  assert_eq(summary.proposal_imported, 1)
  assert_eq(summary.run_confirmed, 1)
  assert_eq(summary.running, 1)
  assert_eq(summary.awaiting_persistence, 1)
  assert_eq(summary.review_queued, 1)
  assert_eq(summary.completed, 1)
  assert_eq(summary.stale, 1)
  assert_eq(summary.failed, 1)
}

///|
test "execution summary owns active runtime policy" {
  let executions = [
    runtime_count_test_execution(@core.TaskExecutionStatus::PacketReady),
    runtime_count_test_execution(@core.TaskExecutionStatus::RunConfirmed),
    runtime_count_test_execution(@core.TaskExecutionStatus::Running),
    runtime_count_test_execution(@core.TaskExecutionStatus::AwaitingPersistence),
    runtime_count_test_execution(@core.TaskExecutionStatus::ReviewQueued),
    runtime_count_test_execution(@core.TaskExecutionStatus::Completed),
    runtime_count_test_execution(@core.TaskExecutionStatus::Stale),
    runtime_count_test_execution(@core.TaskExecutionStatus::Failed),
  ]
  let summary = execution_count_summary(executions)
  assert_eq(summary.active_run_flow(), 2)
  assert_eq(summary.active_or_unresolved(), 5)
  assert_eq(running_execution_count(executions), 5)
}

///|
test "execution lifecycle predicates centralize status groups" {
  assert_true(
    execution_status_is_dispatch_phase(@core.TaskExecutionStatus::PacketReady),
  )
  assert_true(
    execution_status_is_dispatch_phase(
      @core.TaskExecutionStatus::ProposalImported,
    ),
  )
  assert_true(
    execution_status_is_dispatch_phase(@core.TaskExecutionStatus::RunConfirmed),
  )
  assert_true(
    !execution_status_is_dispatch_phase(@core.TaskExecutionStatus::Running),
  )
  assert_true(
    execution_status_needs_attention(@core.TaskExecutionStatus::ReviewQueued),
  )
  assert_true(execution_status_needs_attention(@core.TaskExecutionStatus::Stale))
  assert_true(
    execution_status_is_persistence_or_done(
      @core.TaskExecutionStatus::AwaitingPersistence,
    ),
  )
  assert_true(
    execution_status_is_persistence_or_done(
      @core.TaskExecutionStatus::Completed,
    ),
  )
  assert_true(execution_status_is_active_run(@core.TaskExecutionStatus::Running))
  assert_true(
    execution_status_is_active_run(@core.TaskExecutionStatus::RunConfirmed),
  )
  assert_true(
    !execution_status_has_run_id(@core.TaskExecutionStatus::PacketReady),
  )
  assert_true(
    !execution_status_has_run_id(@core.TaskExecutionStatus::ProposalImported),
  )
  assert_true(execution_status_has_run_id(@core.TaskExecutionStatus::Running))
  assert_true(
    execution_status_requires_review(
      @core.TaskExecutionStatus::AwaitingPersistence,
    ),
  )
  assert_true(
    execution_status_requires_review(@core.TaskExecutionStatus::ReviewQueued),
  )
  assert_true(
    !execution_status_requires_review(@core.TaskExecutionStatus::Completed),
  )
}

///|
test "execution node matching uses lifecycle predicates" {
  assert_true(
    node_matches_execution(
      "city-hall",
      "book",
      @core.TaskExecutionStatus::PacketReady,
    ),
  )
  assert_true(
    node_matches_execution(
      "anomaly-corner",
      "book",
      @core.TaskExecutionStatus::Failed,
    ),
  )
  assert_true(
    node_matches_execution(
      "worker-yard",
      "book",
      @core.TaskExecutionStatus::AwaitingPersistence,
    ),
  )
  assert_true(
    node_matches_execution(
      "book-research",
      "research",
      @core.TaskExecutionStatus::Running,
    ),
  )
  assert_true(
    !node_matches_execution(
      "city-hall",
      "book",
      @core.TaskExecutionStatus::Completed,
    ),
  )
}

///|
test "module execution status class uses lifecycle predicates" {
  assert_true(
    module_execution_status_kind(@core.TaskExecutionStatus::Running) is Running,
  )
  assert_true(
    module_execution_status_kind(
      @core.TaskExecutionStatus::AwaitingPersistence,
    ) is Review,
  )
  assert_true(
    module_execution_status_kind(@core.TaskExecutionStatus::Failed) is Alert,
  )
  assert_true(
    module_execution_status_kind(@core.TaskExecutionStatus::Completed) is
      Complete,
  )
  assert_true(
    module_execution_status_kind(@core.TaskExecutionStatus::PacketReady) is
      Waiting,
  )
  assert_eq(
    module_runtime_status_class(
      module_execution_status_kind(@core.TaskExecutionStatus::Running),
    ),
    "module-status-running",
  )
}

///|
test "execution feed kind classifies visible and quiet lifecycle states" {
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::Running) is
      RunningExecution,
  )
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::RunConfirmed) is
      RunningExecution,
  )
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::AwaitingPersistence) is
      AwaitingPersistenceExecution,
  )
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::Stale) is StaleExecution,
  )
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::Failed) is FailedExecution,
  )
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::Completed) is
      QuietExecution,
  )
  assert_true(
    execution_feed_kind(@core.TaskExecutionStatus::ReviewQueued) is
      QuietExecution,
  )
}

///|
test "execution feed item centralizes runtime event mapping" {
  let running = execution_feed_item(
    runtime_count_test_execution(@core.TaskExecutionStatus::Running),
  )
  assert_eq(running.unwrap().tone, "neutral")
  assert_true(running.unwrap().title.contains("is running"))
  let persisting = execution_feed_item(
    runtime_count_test_execution(@core.TaskExecutionStatus::AwaitingPersistence),
  )
  assert_eq(persisting.unwrap().tone, "hot")
  assert_true(persisting.unwrap().title.contains("awaits MoonBook persistence"))
  let stale = execution_feed_item(
    runtime_count_test_execution(@core.TaskExecutionStatus::Stale),
  )
  assert_eq(stale.unwrap().tone, "alert")
  let failed = execution_feed_item(
    runtime_count_test_execution(@core.TaskExecutionStatus::Failed),
  )
  assert_true(failed.unwrap().title.contains("failed"))
  assert_true(
    execution_feed_item(
      runtime_count_test_execution(@core.TaskExecutionStatus::Completed),
    ) is None,
  )
}

///|
test "execution feed items projects visible execution messages only" {
  let items = execution_feed_items([
    runtime_count_test_execution(@core.TaskExecutionStatus::Running),
    runtime_count_test_execution(@core.TaskExecutionStatus::AwaitingPersistence),
    runtime_count_test_execution(@core.TaskExecutionStatus::Stale),
    runtime_count_test_execution(@core.TaskExecutionStatus::Failed),
    runtime_count_test_execution(@core.TaskExecutionStatus::Completed),
  ])
  assert_eq(items.length(), 4)
  assert_true(items[0].title.contains("is running"))
  assert_true(items[1].title.contains("awaits MoonBook persistence"))
  assert_true(items[2].title.contains("went stale"))
  assert_true(items[3].title.contains("failed"))
}
