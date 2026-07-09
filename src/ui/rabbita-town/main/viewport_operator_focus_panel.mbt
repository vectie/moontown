///|
priv struct OperatorFocusView {
  title : String
  signal : String
  detail : String
  next_label : String
  next_detail : String
  tone : String
}

///|
fn render_operator_focus_panel(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let focus = operator_focus_view(model, workers, executions)
  aside(class="operator-focus-panel operator-focus-\{focus.tone}", [
    h2("Current focus"),
    article(class="operator-focus-primary", [
      p(class="metric-label", "Priority"),
      h3(focus.title),
      p(class="metric-detail", focus.detail),
    ]),
    div(class="operator-focus-grid", [
      operator_focus_item("Signal", focus.signal),
      operator_focus_item(focus.next_label, focus.next_detail),
    ]),
  ])
}

///|
fn operator_focus_item(label : String, detail : String) -> @rabbita.Html {
  article(class="operator-focus-item", [
    p(class="metric-label", label),
    p(class="operator-focus-detail", detail),
  ])
}

///|
fn operator_focus_view(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> OperatorFocusView {
  let workers_summary = worker_count_summary(workers)
  let execution_summary = execution_count_summary(executions)
  let watch_summary = standing_goal_summary(model)
  let decisions = watcher_decision_summary(model)
  let live = live_autonomy_operator_view(
    model,
    fallback_active_workers=workers_summary.online(),
  )
  let failed = execution_summary.failed +
    decisions.failed_count +
    live.failed_template_request_count
  let review = execution_summary.review_queued + decisions.review_count
  if failed > 0 {
    {
      title: "Recover failed work",
      signal: operator_focus_count_sentence(
        failed,
        "failed item needs attention",
        "failed items need attention",
      ),
      detail: "Resolve failed watch or book work before starting new operating load.",
      next_label: "Next opening",
      next_detail: operator_focus_recovery_opening(
        execution_summary,
        decisions,
        live,
      ),
      tone: "alert",
    }
  } else if review > 0 {
    {
      title: "Review queued work",
      signal: operator_focus_count_sentence(
        review,
        "item is waiting for decision",
        "items are waiting for decision",
      ),
      detail: "Clear review work before the next handoff window.",
      next_label: "Next opening",
      next_detail: operator_focus_review_opening(execution_summary, decisions),
      tone: "review",
    }
  } else if watch_summary.enabled_count == 0 {
    {
      title: "Start standing watch",
      signal: "No standing watch is active.",
      detail: "Create one durable watch before relying on unattended town monitoring.",
      next_label: "Town capacity",
      next_detail: operator_focus_count_fragment(
        workers_summary.online(),
        "worker online",
        "workers online",
      ),
      tone: "setup",
    }
  } else if live.pending_template_request_count > 0 {
    {
      title: "Prepare book request",
      signal: operator_focus_count_sentence(
        live.pending_template_request_count,
        "book request is pending",
        "book requests are pending",
      ),
      detail: "Move pending evidence book work to the next review-ready state.",
      next_label: "Watch state",
      next_detail: operator_focus_count_fragment(
        watch_summary.enabled_count,
        "standing watch active",
        "standing watches active",
      ),
      tone: "review",
    }
  } else if execution_summary.active_or_unresolved() > 0 {
    {
      title: "Track active work",
      signal: operator_focus_count_sentence(
        execution_summary.active_or_unresolved(),
        "item is still moving",
        "items are still moving",
      ),
      detail: "Keep active town work visible until it reaches review or completion.",
      next_label: "Town capacity",
      next_detail: operator_focus_count_fragment(
        workers_summary.online(),
        "worker online",
        "workers online",
      ),
      tone: "active",
    }
  } else {
    {
      title: "Monitor live pulse",
      signal: operator_focus_count_sentence(
        watch_summary.enabled_count,
        "standing watch active",
        "standing watches active",
      ),
      detail: "No review-blocked or failed work is visible right now.",
      next_label: "Town capacity",
      next_detail: operator_focus_count_fragment(
        workers_summary.online(),
        "worker online",
        "workers online",
      ),
      tone: "steady",
    }
  }
}

///|
fn operator_focus_recovery_opening(
  executions : ExecutionCountSummary,
  decisions : WatcherDecisionSummary,
  live : LiveAutonomyOperatorView,
) -> String {
  if decisions.failed_count > 0 {
    operator_focus_count_sentence(
      decisions.failed_count,
      "watch result needs recovery",
      "watch results need recovery",
    )
  } else if live.failed_template_request_count > 0 {
    operator_focus_count_sentence(
      live.failed_template_request_count,
      "book request needs recovery",
      "book requests need recovery",
    )
  } else {
    operator_focus_count_sentence(
      executions.failed,
      "town work item needs recovery",
      "town work items need recovery",
    )
  }
}

///|
fn operator_focus_review_opening(
  executions : ExecutionCountSummary,
  decisions : WatcherDecisionSummary,
) -> String {
  if decisions.review_count > 0 {
    operator_focus_count_sentence(
      decisions.review_count,
      "watch result is ready for review",
      "watch results are ready for review",
    )
  } else {
    operator_focus_count_sentence(
      executions.review_queued,
      "town work item is ready for review",
      "town work items are ready for review",
    )
  }
}

///|
fn operator_focus_count_sentence(
  count : Int,
  singular : String,
  plural : String,
) -> String {
  "\{operator_focus_count_fragment(count, singular, plural)}."
}

///|
fn operator_focus_count_fragment(
  count : Int,
  singular : String,
  plural : String,
) -> String {
  if count == 1 {
    "1 \{singular}"
  } else {
    "\{count} \{plural}"
  }
}
