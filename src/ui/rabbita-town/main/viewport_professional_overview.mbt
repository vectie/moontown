///|
fn render_professional_status_strip(model : Model) -> @rabbita.Html {
  let runtime_status = runtime_status_chip_for_model(model)
  div(class="professional-status-strip", [
    status_chip(runtime_status.text, runtime_status.class_name),
    status_chip(daemon_tick_label(model), "chip-neutral"),
    status_chip("Professional view", "chip-book"),
  ])
}

///|
fn render_professional_overview(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let workers_summary = worker_count_summary(workers)
  let executions_summary = execution_count_summary(executions)
  let watch_summary = standing_goal_summary(model)
  let decisions = watcher_decision_summary(model)
  section(class="professional-overview", [
    div(class="professional-overview-head", [
      div(class="professional-overview-copy", [
        p(class="eyebrow", "Town Overview"),
        h2("Current town pulse"),
        p(
          class="summary",
          "The default workspace keeps health, active watches, review needs, book work, and Wenyu map entry visible.",
        ),
      ]),
      div(class="professional-overview-actions", [
        status_chip(
          "Workers online: \{workers_summary.online()}",
          "chip-neutral",
        ),
        status_chip(
          "Review: \{executions_summary.review_queued}",
          professional_review_chip_class(executions_summary.review_queued),
        ),
      ]),
    ]),
    div(class="professional-overview-grid", [
      render_professional_overview_card(
        "Town health",
        professional_town_health_label(model),
        professional_town_health_detail(model),
        professional_town_health_tone(model),
      ),
      render_professional_overview_card(
        "Standing watches",
        watch_summary.enabled_count.to_string(),
        professional_watch_detail(watch_summary),
        "overview-card-book",
      ),
      render_professional_overview_card(
        "Attention",
        professional_attention_label(decisions),
        professional_attention_detail(decisions),
        professional_attention_tone(decisions),
      ),
      render_professional_overview_card(
        "Book queue",
        model.operator_requests.length().to_string(),
        professional_book_queue_detail(model),
        "overview-card-neutral",
      ),
    ]),
  ])
}

///|
fn render_professional_overview_card(
  label : String,
  value : String,
  detail : String,
  tone : String,
) -> @rabbita.Html {
  article(class="professional-overview-card \{tone}", [
    p(class="metric-label", label),
    p(class="professional-overview-value", value),
    p(class="metric-detail", detail),
  ])
}

///|
fn professional_review_chip_class(review_count : Int) -> String {
  if review_count > 0 {
    "chip-alert"
  } else {
    "chip-calm"
  }
}

///|
fn professional_town_health_label(model : Model) -> String {
  if mayor_recovery_active(model) {
    "Needs attention"
  } else if model.paused {
    "Paused"
  } else {
    "Healthy"
  }
}

///|
fn professional_town_health_tone(model : Model) -> String {
  if mayor_recovery_active(model) || model.paused {
    "overview-card-alert"
  } else {
    "overview-card-calm"
  }
}

///|
fn professional_town_health_detail(model : Model) -> String {
  if mayor_recovery_active(model) {
    "Review pressure, stability, energy, or budget before adding more work."
  } else if model.paused {
    "Town updates are paused; active work remains visible for review."
  } else {
    "Town loop is stable enough for standing checks and resident activity."
  }
}

///|
fn professional_watch_detail(summary : StandingGoalSummary) -> String {
  if summary.enabled_count == 0 {
    "Save a standing watch to start durable topic monitoring."
  } else if summary.disabled_count > 0 {
    "\{summary.disabled_count} saved watch is currently paused."
  } else {
    "Enabled watches continue on the town check cadence."
  }
}

///|
fn professional_attention_label(summary : WatcherDecisionSummary) -> String {
  if summary.failed_count > 0 {
    "Failed"
  } else if summary.review_count > 0 {
    "Review"
  } else {
    "Clear"
  }
}

///|
fn professional_attention_tone(summary : WatcherDecisionSummary) -> String {
  if summary.failed_count > 0 {
    "overview-card-alert"
  } else if summary.review_count > 0 {
    "overview-card-review"
  } else {
    "overview-card-calm"
  }
}

///|
fn professional_attention_detail(summary : WatcherDecisionSummary) -> String {
  if summary.failed_count > 0 {
    "\{summary.failed_count} watcher run needs recovery."
  } else if summary.review_count > 0 {
    "\{summary.review_count} watcher update is waiting for review."
  } else {
    "No watcher failures or review-blocked updates are waiting."
  }
}

///|
fn professional_book_queue_detail(model : Model) -> String {
  let template_requests = live_autonomy_operator_view(
      model,
      fallback_active_workers=0,
    ).template_request_count
  if template_requests > 0 {
    "\{template_requests} book setup request is visible in the town queue."
  } else {
    "Create a book request only when a new durable knowledge area is needed."
  }
}
