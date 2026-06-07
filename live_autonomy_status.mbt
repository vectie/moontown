///|
priv struct LiveAutonomyBlockerContext {
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
fn live_autonomy_status(
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
fn live_autonomy_stable_waiting_blockers_for(
  context : LiveAutonomyBlockerContext,
) -> Array[String] {
  let blockers : Array[String] = []
  append_live_autonomy_strings(
    blockers,
    live_autonomy_workflow_blockers(context),
  )
  append_live_autonomy_strings(
    blockers,
    live_autonomy_standing_goal_blockers(context),
  )
  append_live_autonomy_strings(
    blockers,
    live_autonomy_planbook_blockers(context),
  )
  append_live_autonomy_strings(
    blockers,
    live_autonomy_template_request_blockers(context),
  )
  blockers
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
fn live_autonomy_stability_probe_is_stable(
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
fn live_autonomy_due_in_label(ticks : Int) -> String {
  let seconds = ticks * standing_goal_tick_seconds()
  if seconds <= 0 {
    "due now"
  } else if seconds < 60 {
    "\{seconds}s"
  } else if seconds < 3600 {
    "\{seconds / 60}m"
  } else {
    let hours = seconds / 3600
    let minutes = seconds % 3600 / 60
    if minutes == 0 {
      "\{hours}h"
    } else {
      "\{hours}h \{minutes}m"
    }
  }
}
