///|
fn assigned_worker_id(decision : @dispatch.RouteDecision) -> String? {
  match decision {
    Assigned(plan) => Some(plan.worker_id)
    _ => None
  }
}

///|
fn sync_worker_from_execution(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  match execution.assigned_worker_id {
    Some(worker_id) =>
      state.set_worker_status(
        worker_id,
        worker_status_for_execution(execution.status),
      )
    None => ()
  }
}

///|
fn worker_status_for_execution(
  status : @core.TaskExecutionStatus,
) -> @core.WorkerStatus {
  match status {
    @core.TaskExecutionStatus::PacketReady => @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::ProposalImported => @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::RunConfirmed => @core.WorkerStatus::Running
    @core.TaskExecutionStatus::Running => @core.WorkerStatus::Running
    @core.TaskExecutionStatus::AwaitingPersistence =>
      @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::ReviewQueued => @core.WorkerStatus::Idle
    @core.TaskExecutionStatus::Completed => @core.WorkerStatus::Idle
    @core.TaskExecutionStatus::Stale => @core.WorkerStatus::Blocked
    @core.TaskExecutionStatus::Failed => @core.WorkerStatus::Idle
  }
}

///|
fn release_orphaned_blocked_workers(state : @core.TownState) -> Unit {
  let workers = state.workers.copy()
  for worker in workers {
    if worker.status == @core.WorkerStatus::Idle ||
      worker.status == @core.WorkerStatus::Offline {
      continue
    }
    match latest_execution_for_worker(state, worker.id) {
      Some(execution) if worker_should_be_released(execution) => {
        state.set_worker_status(worker.id, @core.WorkerStatus::Idle)
        state.record_event(
          @core.TownEvent::new(
            id="event-worker-release-\{state.events.length()}-\{worker.id}",
            kind="recovery",
            detail="Mayor released blocked worker \{worker.id} after terminal execution \{execution.task_id} reached \{execution.status.to_string()}.",
            related_task_id=Some(execution.task_id),
            related_book_id=Some(execution.book_id),
            related_run_id=execution.run_id,
          ),
        )
      }
      None => {
        state.set_worker_status(worker.id, @core.WorkerStatus::Idle)
        state.record_event(
          @core.TownEvent::new(
            id="event-worker-release-\{state.events.length()}-\{worker.id}",
            kind="recovery",
            detail="Mayor released non-idle worker \{worker.id} because no live or terminal execution still owns it.",
          ),
        )
      }
      _ => ()
    }
  }
}

///|
fn latest_execution_for_worker(
  state : @core.TownState,
  worker_id : String,
) -> @core.TaskExecutionRecord? {
  let mut latest : @core.TaskExecutionRecord? = None
  for execution in state.executions {
    match execution.assigned_worker_id {
      Some(id) if id == worker_id => latest = Some(execution)
      _ => ()
    }
  }
  latest
}

///|
fn worker_should_be_released(execution : @core.TaskExecutionRecord) -> Bool {
  match execution.status {
    @core.TaskExecutionStatus::Completed => true
    @core.TaskExecutionStatus::ReviewQueued => true
    @core.TaskExecutionStatus::Failed => true
    @core.TaskExecutionStatus::Stale => true
    _ => false
  }
}
