///|
fn supervision_directive_for(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> MayorSupervisionDirective? {
  ignore(state)
  match stale_supervision_directive(execution, tick) {
    Some(directive) => return Some(directive)
    None => ()
  }
  match execution.status {
    PacketReady => packet_ready_supervision_directive(execution, tick)
    AwaitingPersistence => awaiting_persistence_supervision_directive(execution)
    ReviewQueued => review_queued_supervision_directive(execution, tick)
    Stale | Failed => failed_or_stale_supervision_directive(execution, tick)
    _ => None
  }
}

///|
fn stale_supervision_directive(
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> MayorSupervisionDirective? {
  let stale = if execution.status == Running || execution.status == RunConfirmed {
    execution.stale_after_tick <= tick
  } else {
    false
  }
  if !stale {
    return None
  }
  Some({
    kind: if execution.attempt < 3 {
      mark_stale_retry_directive_kind()
    } else {
      mark_stale_failed_directive_kind()
    },
    task_id: execution.task_id,
    execution_status: Stale,
    detail: "Execution \{execution.task_id} missed its heartbeat window and needs mayor recovery.",
    next_retry_tick: if execution.attempt < 3 {
      Some(tick + retry_backoff_ticks(execution.attempt))
    } else {
      None
    },
  })
}

///|
fn packet_ready_supervision_directive(
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> MayorSupervisionDirective? {
  match execution.next_retry_tick {
    Some(next_tick) if next_tick > tick => None
    _ =>
      Some({
        kind: retry_execution_directive_kind(),
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} is queued as packet-ready and should launch when live worker capacity is available.",
        next_retry_tick: Some(tick + retry_backoff_ticks(1)),
      })
  }
}

///|
fn awaiting_persistence_supervision_directive(
  execution : @core.TaskExecutionRecord,
) -> MayorSupervisionDirective? {
  Some({
    kind: @scheduler.persist_result_action_kind(),
    task_id: execution.task_id,
    execution_status: execution.status,
    detail: "Execution \{execution.task_id} should be persisted into MoonBook.",
    next_retry_tick: None,
  })
}

///|
fn review_queued_supervision_directive(
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> MayorSupervisionDirective? {
  match execution.next_retry_tick {
    Some(next_tick) if execution.attempt < 3 && next_tick <= tick =>
      Some({
        kind: retry_execution_directive_kind(),
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} is review-queued with fixable quality gaps and is eligible for an in-place repair retry.",
        next_retry_tick: Some(tick + retry_backoff_ticks(execution.attempt + 1)),
      })
    _ =>
      if execution.heartbeat_tick == 0 {
        Some({
          kind: @scheduler.review_sync_action_kind(),
          task_id: execution.task_id,
          execution_status: execution.status,
          detail: "Execution \{execution.task_id} is waiting for keeper review sync.",
          next_retry_tick: None,
        })
      } else {
        None
      }
  }
}

///|
fn failed_or_stale_supervision_directive(
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> MayorSupervisionDirective? {
  match execution.next_retry_tick {
    _ if recoverable_profile_dispatch_failure(execution) &&
      execution.attempt < 5 =>
      Some({
        kind: retry_execution_directive_kind(),
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} failed during profile dispatch and is eligible for a bounded self-heal retry after profile routing/provisioning changes.",
        next_retry_tick: Some(tick + retry_backoff_ticks(execution.attempt + 1)),
      })
    Some(next_tick) if execution.attempt < 3 && next_tick <= tick =>
      Some({
        kind: retry_execution_directive_kind(),
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} is eligible for a supervised retry.",
        next_retry_tick: Some(tick + retry_backoff_ticks(execution.attempt + 1)),
      })
    None if execution.attempt < 3 =>
      Some({
        kind: retry_execution_directive_kind(),
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} has no scheduled retry but is still within the bounded recovery budget.",
        next_retry_tick: Some(tick + retry_backoff_ticks(execution.attempt + 1)),
      })
    _ => None
  }
}

///|
fn recoverable_profile_dispatch_failure(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  execution.summary.contains("Unknown external proposal profile") ||
  execution.summary.contains("Proposal import failed") ||
  execution.summary.contains("Resource temporarily unavailable")
}

///|
fn retry_backoff_ticks(attempt : Int) -> Int {
  match attempt {
    0 | 1 => 1
    2 => 3
    _ => 6
  }
}
