///|
fn push_worker_alert_messages(
  feed : Array[FeedItem],
  workers : Array[WorkerSim],
  watcher_idle_detail : String,
) -> Unit {
  ignore(push_feed_items(feed, worker_feed_items(workers, watcher_idle_detail)))
}

///|
fn worker_feed_items(
  workers : Array[WorkerSim],
  watcher_idle_detail : String,
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  for worker in workers {
    ignore(
      push_optional_feed_item(
        feed,
        worker_feed_item(worker, watcher_idle_detail),
      ),
    )
  }
  feed
}

///|
priv enum WorkerFeedKind {
  BlockedWorker
  OnDutyWatcher
  QuietWorker
}

///|
fn worker_feed_kind(worker : WorkerSim) -> WorkerFeedKind {
  match worker.status {
    @core.WorkerStatus::Blocked => BlockedWorker
    @core.WorkerStatus::Idle if is_on_duty_watcher(worker) => OnDutyWatcher
    _ => QuietWorker
  }
}

///|
fn worker_feed_item(
  worker : WorkerSim,
  watcher_idle_detail : String,
) -> FeedItem? {
  match worker_feed_kind(worker) {
    BlockedWorker =>
      Some({
        title: "\{worker.title} stalled",
        detail: "Mayor should recover this lane before the next 30-minute watcher cycle.",
        tone: "alert",
      })
    OnDutyWatcher =>
      Some({
        title: "\{worker.title} is on duty",
        detail: watcher_idle_detail,
        tone: "calm",
      })
    QuietWorker => None
  }
}

///|
fn push_execution_messages(
  feed : Array[FeedItem],
  executions : Array[@core.TaskExecutionRecord],
) -> Unit {
  ignore(push_feed_items(feed, execution_feed_items(executions)))
}

///|
fn execution_feed_items(
  executions : Array[@core.TaskExecutionRecord],
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  for execution in executions {
    ignore(push_optional_feed_item(feed, execution_feed_item(execution)))
  }
  feed
}

///|
priv enum ExecutionFeedKind {
  RunningExecution
  AwaitingPersistenceExecution
  StaleExecution
  FailedExecution
  QuietExecution
}

///|
fn execution_feed_kind(status : @core.TaskExecutionStatus) -> ExecutionFeedKind {
  if execution_status_is_active_run(status) {
    RunningExecution
  } else {
    match status {
      @core.TaskExecutionStatus::AwaitingPersistence =>
        AwaitingPersistenceExecution
      @core.TaskExecutionStatus::Stale => StaleExecution
      @core.TaskExecutionStatus::Failed => FailedExecution
      @core.TaskExecutionStatus::PacketReady
      | @core.TaskExecutionStatus::ProposalImported
      | @core.TaskExecutionStatus::ReviewQueued
      | @core.TaskExecutionStatus::Completed => QuietExecution
      @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running => QuietExecution
    }
  }
}

///|
fn execution_feed_item(execution : @core.TaskExecutionRecord) -> FeedItem? {
  match execution_feed_kind(execution.status) {
    RunningExecution =>
      Some({
        title: "\{execution.task_id} is running",
        detail: execution.summary,
        tone: "neutral",
      })
    AwaitingPersistenceExecution =>
      Some({
        title: "\{execution.task_id} awaits MoonBook persistence",
        detail: "The run is done; the next town action is keeper persistence and evidence capture.",
        tone: "hot",
      })
    StaleExecution =>
      Some({
        title: "\{execution.task_id} went stale",
        detail: "Mayor supervision should recover the missed heartbeat or retry the lane.",
        tone: "alert",
      })
    FailedExecution =>
      Some({
        title: "\{execution.task_id} failed",
        detail: "A proposal/run failure surfaced in the packet lifecycle.",
        tone: "alert",
      })
    QuietExecution => None
  }
}
