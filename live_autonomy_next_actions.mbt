///|
priv struct LiveAutonomyActionContext {
  blockers : LiveAutonomyBlockerContext
  watcher_records : Array[@core.WatcherRunRecord]
  transient_infrastructure_debt : Int
}

///|
fn live_autonomy_next_actions_for(
  context : LiveAutonomyActionContext,
) -> Array[String] {
  let actions : Array[String] = []
  let latest_decision = live_autonomy_latest_watcher_decision(context)
  append_live_autonomy_strings(actions, live_autonomy_workflow_actions(context))
  append_live_autonomy_strings(actions, live_autonomy_planbook_actions(context))
  append_live_autonomy_strings(
    actions,
    live_autonomy_template_request_actions(context),
  )
  append_live_autonomy_strings(
    actions,
    live_autonomy_watcher_decision_actions(latest_decision),
  )
  append_live_autonomy_strings(
    actions,
    live_autonomy_idle_actions(context, latest_decision),
  )
  actions
}

///|
fn live_autonomy_latest_watcher_decision(
  context : LiveAutonomyActionContext,
) -> @core.WatcherDecisionKind? {
  match latest_watcher_record(context.watcher_records) {
    Some(record) => Some(watcher_record_effective_decision(record))
    None => None
  }
}

///|
fn live_autonomy_workflow_actions(
  context : LiveAutonomyActionContext,
) -> Array[String] {
  let actions : Array[String] = []
  let blockers = context.blockers
  if blockers.blocked > 0 {
    actions.push(
      "Mayor should recover blocked or stale work before dispatching more tasks.",
    )
  }
  if blockers.review > 0 {
    actions.push(
      "Review queue is visible for keeper/operator judgment, but routine queued review does not block the live watch loop.",
    )
  }
  if blockers.due_goals > 0 {
    actions.push("Dispatch due standing goals on the next daemon tick.")
  }
  actions
}

///|
fn live_autonomy_planbook_actions(
  context : LiveAutonomyActionContext,
) -> Array[String] {
  let actions : Array[String] = []
  let blockers = context.blockers
  if blockers.planbook_repair_active > 0 {
    actions.push(
      "PlanBook has an active self-repair packet; monitor repair status before creating another one.",
    )
  } else if blockers.planbook_open > 0 {
    actions.push(
      "PlanBook has \{blockers.planbook_open} open self-build gap(s); the next daemon tick will queue and dispatch the top bounded Codex ACP repair packet when no repair is active.",
    )
  }
  actions
}

///|
fn live_autonomy_template_request_actions(
  context : LiveAutonomyActionContext,
) -> Array[String] {
  let actions : Array[String] = []
  let blockers = context.blockers
  if blockers.failed_book_template_requests > 0 {
    actions.push(
      "Inspect failed book-template request configs before retrying Moondesk book creation.",
    )
  } else if blockers.pending_book_template_requests > 0 {
    actions.push(
      "Process pending book-template requests so requested books become real MoonBook workspaces.",
    )
  }
  actions
}

///|
fn live_autonomy_watcher_decision_actions(
  latest_decision : @core.WatcherDecisionKind?,
) -> Array[String] {
  let actions : Array[String] = []
  match latest_decision {
    Some(decision) =>
      match decision {
        @core.WatcherDecisionKind::Update =>
          actions.push(
            "Promote the latest watcher update into accepted book/projection state if review passes.",
          )
        @core.WatcherDecisionKind::NeedsReview =>
          actions.push(
            "Review the latest watcher finding before counting it as progress.",
          )
        @core.WatcherDecisionKind::Failed =>
          actions.push(
            "Retry the latest watcher failure with backoff and preserve the blocker.",
          )
        @core.WatcherDecisionKind::Deferred =>
          actions.push(
            "Latest watcher is deferred; keep it as infrastructure retry/accounting debt until a real MoonBook terminal marker arrives.",
          )
        _ => ()
      }
    None => ()
  }
  actions
}

///|
fn live_autonomy_idle_actions(
  context : LiveAutonomyActionContext,
  latest_decision : @core.WatcherDecisionKind?,
) -> Array[String] {
  let actions : Array[String] = []
  let blockers = context.blockers
  if blockers.active_workers == 0 &&
    blockers.due_goals == 0 &&
    latest_decision != Some(@core.WatcherDecisionKind::Deferred) {
    if context.transient_infrastructure_debt > 0 {
      actions.push(
        "Historical transient infrastructure debt is visible and inspectable; keep watching unless the count grows or the latest watcher becomes deferred.",
      )
    }
    actions.push(
      "Town is watching; wait for the next real-world cadence or submit a new request.",
    )
  }
  actions
}

///|
