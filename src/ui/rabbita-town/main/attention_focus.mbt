///|
priv struct AttentionFocusView {
  title : String
  signal : String
  detail : String
  next_label : String
  next_detail : String
  tone : String
}

///|
fn attention_focus_view(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> AttentionFocusView {
  let workers_summary = worker_count_summary(workers)
  let execution_summary = execution_count_summary(executions)
  let watch_summary = standing_goal_summary(model)
  let decisions = watcher_decision_summary(model)
  let live = live_autonomy_operator_view(
    model,
    fallback_active_workers=workers_summary.online(),
  )
  let attention = professional_attention_summary(model, executions)
  if professional_attention_has_failed(attention) {
    {
      title: "Recover failed work",
      signal: attention_focus_count_fragment(
        attention.failed_count,
        "failed item",
        "failed items",
      ),
      detail: "Resolve failed watch or book work before starting new operating load.",
      next_label: "Next opening",
      next_detail: attention_focus_recovery_opening(
        execution_summary,
        decisions,
        live,
      ),
      tone: "alert",
    }
  } else if professional_attention_has_review(attention) {
    {
      title: "Review queued work",
      signal: attention_focus_count_fragment(
        attention.review_count,
        "review",
        "reviews",
      ),
      detail: "Clear review work before the next handoff window.",
      next_label: "Next opening",
      next_detail: attention_focus_review_opening(execution_summary, decisions),
      tone: "review",
    }
  } else if watch_summary.enabled_count == 0 {
    {
      title: "Start standing watch",
      signal: "No watch active",
      detail: "Create one durable watch before relying on unattended town monitoring.",
      next_label: "Town capacity",
      next_detail: attention_focus_count_fragment(
        workers_summary.online(),
        "worker online",
        "workers online",
      ),
      tone: "setup",
    }
  } else if live.pending_template_request_count > 0 {
    {
      title: "Prepare book request",
      signal: attention_focus_count_fragment(
        live.pending_template_request_count,
        "book pending",
        "books pending",
      ),
      detail: "Move pending evidence book work to the next review-ready state.",
      next_label: "Watch state",
      next_detail: attention_focus_count_fragment(
        watch_summary.enabled_count,
        "standing watch active",
        "standing watches active",
      ),
      tone: "review",
    }
  } else if execution_summary.active_or_unresolved() > 0 {
    {
      title: "Track active work",
      signal: attention_focus_count_fragment(
        execution_summary.active_or_unresolved(),
        "item moving",
        "items moving",
      ),
      detail: "Keep active town work visible until it reaches review or completion.",
      next_label: "Town capacity",
      next_detail: attention_focus_count_fragment(
        workers_summary.online(),
        "worker online",
        "workers online",
      ),
      tone: "active",
    }
  } else {
    {
      title: "Monitor live pulse",
      signal: attention_focus_count_fragment(
        watch_summary.enabled_count,
        "watch active",
        "watches active",
      ),
      detail: "No review-blocked or failed work is visible right now.",
      next_label: "Town capacity",
      next_detail: attention_focus_count_fragment(
        workers_summary.online(),
        "worker online",
        "workers online",
      ),
      tone: "steady",
    }
  }
}

///|
fn attention_focus_recovery_opening(
  executions : ExecutionCountSummary,
  decisions : WatcherDecisionSummary,
  live : LiveAutonomyOperatorView,
) -> String {
  if decisions.failed_count > 0 {
    attention_focus_count_fragment(
      decisions.failed_count,
      "watch recovery",
      "watch recoveries",
    )
  } else if live.failed_template_request_count > 0 {
    attention_focus_count_fragment(
      live.failed_template_request_count,
      "book recovery",
      "book recoveries",
    )
  } else {
    attention_focus_count_fragment(
      executions.failed,
      "town recovery",
      "town recoveries",
    )
  }
}

///|
fn attention_focus_review_opening(
  executions : ExecutionCountSummary,
  decisions : WatcherDecisionSummary,
) -> String {
  if decisions.review_count > 0 {
    attention_focus_count_fragment(
      decisions.review_count,
      "watch review",
      "watch reviews",
    )
  } else {
    attention_focus_count_fragment(
      executions.review_queued,
      "town review",
      "town reviews",
    )
  }
}

///|
fn attention_focus_count_fragment(
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
