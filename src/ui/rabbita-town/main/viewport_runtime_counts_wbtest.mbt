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
    role,
    book_id: "book",
    status,
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
    task_id="task-town-shell-code-patch",
    book_id="wenyu-town-shell",
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
    worker_feed_kind(runtime_count_test_worker(Blocked))
    is BlockedWorker,
  )
  assert_true(
    worker_feed_kind(
      runtime_count_test_worker_with_role(
        Idle,
        "Standing Watcher",
      ),
    )
    is OnDutyWatcher,
  )
  assert_true(
    worker_feed_kind(runtime_count_test_worker(Idle))
    is QuietWorker,
  )
  assert_true(
    worker_feed_kind(
      runtime_count_test_worker_with_role(
        Running,
        "Standing Watcher",
      ),
    )
    is QuietWorker,
  )
}

///|
test "worker feed item centralizes worker alert and watcher mapping" {
  let blocked = worker_feed_item(
    runtime_count_test_worker(Blocked),
    "watcher idle",
  )
  assert_eq(blocked.unwrap().tone, "alert")
  assert_true(blocked.unwrap().title.contains("stalled"))
  assert_true(blocked.unwrap().detail.contains("Mayor should recover"))
  let watcher = worker_feed_item(
    runtime_count_test_worker_with_role(
      Idle,
      "Standing Watcher",
    ),
    "next check waits for real time",
  )
  assert_eq(watcher.unwrap().tone, "calm")
  assert_true(watcher.unwrap().title.contains("is on duty"))
  assert_eq(watcher.unwrap().detail, "next check waits for real time")
  assert_true(
    worker_feed_item(
      runtime_count_test_worker(Idle),
      "watcher idle",
    )
    is None,
  )
  assert_true(
    worker_feed_item(
      runtime_count_test_worker_with_role(
        Running,
        "Standing Watcher",
      ),
      "watcher idle",
    )
    is None,
  )
}

///|
test "push worker alert messages delegates item projection" {
  let feed : Array[FeedItem] = []
  push_worker_alert_messages(
    feed,
    [
      runtime_count_test_worker(Blocked),
      runtime_count_test_worker_with_role(
        Idle,
        "Standing Watcher",
      ),
      runtime_count_test_worker(Running),
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
      runtime_count_test_worker(Blocked),
      runtime_count_test_worker_with_role(
        Idle,
        "Standing Watcher",
      ),
      runtime_count_test_worker(Running),
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
    runtime_count_test_execution(PacketReady),
    runtime_count_test_execution(ProposalImported),
    runtime_count_test_execution(RunConfirmed),
    runtime_count_test_execution(Running),
    runtime_count_test_execution(AwaitingPersistence),
    runtime_count_test_execution(ReviewQueued),
    runtime_count_test_execution(Completed),
    runtime_count_test_execution(Stale),
    runtime_count_test_execution(Failed),
  ])
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
    runtime_count_test_execution(PacketReady),
    runtime_count_test_execution(RunConfirmed),
    runtime_count_test_execution(Running),
    runtime_count_test_execution(AwaitingPersistence),
    runtime_count_test_execution(ReviewQueued),
    runtime_count_test_execution(Completed),
    runtime_count_test_execution(Stale),
    runtime_count_test_execution(Failed),
  ]
  let summary = execution_count_summary(executions)
  assert_eq(summary.active_run_flow(), 2)
  assert_eq(summary.active_or_unresolved(), 5)
}

///|
test "execution lifecycle predicates centralize status groups" {
  assert_true(
    execution_status_needs_attention(ReviewQueued),
  )
  assert_true(
    execution_status_needs_attention(Stale),
  )
  assert_true(
    execution_status_is_active_run(Running),
  )
  assert_true(
    execution_status_is_active_run(RunConfirmed),
  )
  assert_true(
    !execution_status_has_run_id(PacketReady),
  )
  assert_true(
    !execution_status_has_run_id(ProposalImported),
  )
  assert_true(execution_status_has_run_id(Running))
  assert_true(
    execution_status_requires_review(
      AwaitingPersistence,
    ),
  )
  assert_true(
    execution_status_requires_review(ReviewQueued),
  )
  assert_true(
    !execution_status_requires_review(Completed),
  )
}

///|
test "module execution status class uses lifecycle predicates" {
  assert_true(
    module_execution_status_kind(Running) is Running,
  )
  assert_true(
    module_execution_status_kind(AwaitingPersistence)
    is Review,
  )
  assert_true(
    module_execution_status_kind(Failed) is Alert,
  )
  assert_true(
    module_execution_status_kind(Completed)
    is Complete,
  )
  assert_true(
    module_execution_status_kind(PacketReady)
    is Waiting,
  )
  assert_eq(
    module_runtime_status_class(
      module_execution_status_kind(Running),
    ),
    "module-status-running",
  )
}

///|
test "execution feed kind classifies visible and quiet lifecycle states" {
  assert_true(
    execution_feed_kind(Running) is RunningExecution,
  )
  assert_true(
    execution_feed_kind(RunConfirmed)
    is RunningExecution,
  )
  assert_true(
    execution_feed_kind(AwaitingPersistence)
    is AwaitingPersistenceExecution,
  )
  assert_true(
    execution_feed_kind(Stale) is StaleExecution,
  )
  assert_true(
    execution_feed_kind(Failed) is FailedExecution,
  )
  assert_true(
    execution_feed_kind(Completed) is QuietExecution,
  )
  assert_true(
    execution_feed_kind(ReviewQueued)
    is QuietExecution,
  )
}

///|
test "execution feed item centralizes runtime event mapping" {
  let running = execution_feed_item(
    runtime_count_test_execution(Running),
  )
  assert_eq(running.unwrap().tone, "neutral")
  assert_eq(running.unwrap().title, "Town shell code patch is running")
  assert_true(!running.unwrap().title.contains("task-"))
  assert_true(!running.unwrap().detail.contains("task-"))
  let persisting = execution_feed_item(
    runtime_count_test_execution(AwaitingPersistence),
  )
  assert_eq(persisting.unwrap().tone, "hot")
  assert_eq(
    persisting.unwrap().title,
    "Town shell code patch is waiting for MoonBook save",
  )
  let stale = execution_feed_item(
    runtime_count_test_execution(Stale),
  )
  assert_eq(stale.unwrap().tone, "alert")
  assert_eq(stale.unwrap().title, "Town shell code patch needs recovery")
  let failed = execution_feed_item(
    runtime_count_test_execution(Failed),
  )
  assert_eq(failed.unwrap().title, "Town shell code patch failed")
  assert_true(
    execution_feed_item(
      runtime_count_test_execution(Completed),
    )
    is None,
  )
}

///|
test "execution feed items projects visible execution messages only" {
  let items = execution_feed_items([
    runtime_count_test_execution(Running),
    runtime_count_test_execution(AwaitingPersistence),
    runtime_count_test_execution(Stale),
    runtime_count_test_execution(Failed),
    runtime_count_test_execution(Completed),
  ])
  assert_eq(items.length(), 4)
  assert_eq(items[0].title, "Town shell code patch is running")
  assert_eq(
    items[1].title,
    "Town shell code patch is waiting for MoonBook save",
  )
  assert_eq(items[2].title, "Town shell code patch needs recovery")
  assert_eq(items[3].title, "Town shell code patch failed")
}

///|
test "execution display labels hide raw task ids from default feed" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="task-unknown-runtime-id",
    book_id="ai-garden",
    packet_id="packet-task-unknown-runtime-id",
    packet_path="packet.json",
    status=Running,
    summary="Running task-unknown-runtime-id.",
    output_contract="contract",
  )
  let item = execution_feed_item(execution).unwrap()
  assert_eq(item.title, "AI Garden work is running")
  assert_true(!item.title.contains("task-"))
  assert_true(!item.detail.contains("task-"))
}
