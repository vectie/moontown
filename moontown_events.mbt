///|
fn route_event(
  decision : @dispatch.RouteDecision,
  index : Int,
) -> @core.TownEvent {
  match decision {
    Assigned(plan) =>
      @core.TownEvent::new(
        id="event-route-\{index}",
        kind="assignment",
        detail="\{plan.task_id} -> \{plan.worker_id} (\{plan.reason})",
        related_task_id=Some(plan.task_id),
        related_book_id=Some(plan.book_id),
      )
    Escalated(reason) =>
      @core.TownEvent::new(
        id="event-route-\{index}",
        kind="escalation",
        detail=reason,
      )
    Deferred(reason) =>
      @core.TownEvent::new(
        id="event-route-\{index}",
        kind="deferred",
        detail=reason,
      )
  }
}

///|
fn execution_event(
  execution : @core.TaskExecutionRecord,
  index : Int,
) -> @core.TownEvent {
  let proposal = execution.proposal_id.unwrap_or("draft")
  @core.TownEvent::new(
    id="event-exec-\{index}",
    kind="execution",
    detail="\{execution.task_id} -> \{execution.status.to_string()} / proposal=\{proposal}",
    related_task_id=Some(execution.task_id),
    related_book_id=Some(execution.book_id),
    related_proposal_id=execution.proposal_id,
    related_run_id=execution.run_id,
  )
}

///|
fn append_routes_and_events(state : @core.TownState) -> Unit {
  for i in 0..<state.tasks.length() {
    let task = state.tasks[i]
    let decision = @dispatch.route_task(
      state,
      @dispatch.RouteRequest::new(task~),
    )
    state.record_event(route_event(decision, i))
  }
  for i in 0..<state.executions.length() {
    state.record_event(execution_event(state.executions[i], i))
  }
}
