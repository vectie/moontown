///|
pub(all) struct LiveAutonomyBlockerContext {
  active_workers : Int
  review : Int
  blocked : Int
  failed : Int
  due_goals : Int
  planbook_open : Int
  planbook_repair_active : Int
  pending_book_template_requests : Int
  failed_book_template_requests : Int
}

///|
pub(all) struct LiveAutonomyWaitingState {
  stable_waiting : Bool
  stable_waiting_observation_streak : Int
  stable_waiting_blockers : Array[String]
}

///|
pub(all) struct LiveAutonomyActionContext {
  blockers : LiveAutonomyBlockerContext
  latest_watcher_decision : @core.WatcherDecisionKind?
  transient_infrastructure_debt : Int
}

///|
pub fn live_autonomy_status(
  active_workers : Int,
  review : Int,
  blocked : Int,
) -> String {
  let _ = review
  if blocked > 0 {
    "needs-recovery"
  } else if active_workers > 0 {
    "working"
  } else {
    "watching"
  }
}

///|
pub fn live_autonomy_waiting_state(
  blockers : LiveAutonomyBlockerContext,
  prior_stable_waiting_observation_streak : Int,
) -> LiveAutonomyWaitingState {
  let stable_waiting_blockers = live_autonomy_stable_waiting_blockers_for(
    blockers,
  )
  let stable_waiting = stable_waiting_blockers.is_empty()
  {
    stable_waiting,
    stable_waiting_observation_streak: next_live_autonomy_stable_waiting_observation_streak(
      stable_waiting, prior_stable_waiting_observation_streak,
    ),
    stable_waiting_blockers,
  }
}

///|
pub fn next_live_autonomy_stable_waiting_observation_streak(
  stable_waiting : Bool,
  prior_stable_waiting_observation_streak : Int,
) -> Int {
  if stable_waiting {
    prior_stable_waiting_observation_streak + 1
  } else {
    0
  }
}

///|
pub fn live_autonomy_stable_waiting_blockers_for(
  context : LiveAutonomyBlockerContext,
) -> Array[String] {
  let blockers : Array[String] = []
  append_strings(blockers, live_autonomy_workflow_blockers(context))
  append_strings(blockers, live_autonomy_standing_goal_blockers(context))
  append_strings(blockers, live_autonomy_planbook_blockers(context))
  append_strings(blockers, live_autonomy_template_request_blockers(context))
  blockers
}

///|
pub fn live_autonomy_stability_probe_is_stable(
  probe : LiveAutonomyStabilityProbe,
) -> Bool {
  live_autonomy_stable_waiting_blockers_for({
    active_workers: probe.active_worker_count,
    review: probe.review_count,
    blocked: probe.blocked_count,
    failed: probe.failed_count,
    due_goals: probe.due_goal_count,
    planbook_open: probe.planbook_open_count,
    planbook_repair_active: probe.planbook_repair_active_count,
    pending_book_template_requests: probe.pending_book_template_request_count,
    failed_book_template_requests: probe.failed_book_template_request_count,
  }).is_empty()
}

///|
pub fn live_autonomy_next_actions_for(
  context : LiveAutonomyActionContext,
) -> Array[String] {
  let actions : Array[String] = []
  let latest_decision = context.latest_watcher_decision
  append_strings(actions, live_autonomy_workflow_actions(context))
  append_strings(actions, live_autonomy_planbook_actions(context))
  append_strings(actions, live_autonomy_template_request_actions(context))
  append_strings(
    actions,
    live_autonomy_watcher_decision_actions(latest_decision),
  )
  append_strings(actions, live_autonomy_idle_actions(context, latest_decision))
  actions
}

///|
fn live_autonomy_workflow_blockers(
  context : LiveAutonomyBlockerContext,
) -> Array[String] {
  let blockers : Array[String] = []
  if context.active_workers > 0 {
    blockers.push("active workers or executions: \{context.active_workers}")
  }
  if context.review > 0 {
    blockers.push("review queue: \{context.review}")
  }
  if context.blocked > 0 {
    blockers.push("blocked or unhealthy items: \{context.blocked}")
  }
  if context.failed > 0 {
    blockers.push("unresolved failures: \{context.failed}")
  }
  blockers
}

///|
fn live_autonomy_standing_goal_blockers(
  context : LiveAutonomyBlockerContext,
) -> Array[String] {
  let blockers : Array[String] = []
  if context.due_goals > 0 {
    blockers.push("due standing goals: \{context.due_goals}")
  }
  blockers
}

///|
fn live_autonomy_planbook_blockers(
  context : LiveAutonomyBlockerContext,
) -> Array[String] {
  let blockers : Array[String] = []
  if context.planbook_open > 0 {
    blockers.push("PlanBook open gaps: \{context.planbook_open}")
  }
  if context.planbook_repair_active > 0 {
    blockers.push("PlanBook active repairs: \{context.planbook_repair_active}")
  }
  blockers
}

///|
fn live_autonomy_template_request_blockers(
  context : LiveAutonomyBlockerContext,
) -> Array[String] {
  let blockers : Array[String] = []
  if context.pending_book_template_requests > 0 {
    blockers.push(
      "pending book-template requests: \{context.pending_book_template_requests}",
    )
  }
  if context.failed_book_template_requests > 0 {
    blockers.push(
      "failed book-template requests: \{context.failed_book_template_requests}",
    )
  }
  blockers
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
      "Inspect failed book-template request configs before retrying MoonDesk book creation.",
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
        Update =>
          actions.push(
            "Promote the latest watcher update into accepted book/projection state if review passes.",
          )
        NeedsReview =>
          actions.push(
            "Review the latest watcher finding before counting it as progress.",
          )
        Failed =>
          actions.push(
            "Retry the latest watcher failure with backoff and preserve the blocker.",
          )
        Deferred =>
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
    latest_decision != Some(Deferred) {
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
fn append_strings(target : Array[String], source : Array[String]) -> Unit {
  for item in source {
    target.push(item)
  }
}
