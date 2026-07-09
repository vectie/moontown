///|
fn render_town_launchpad(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let workers_summary = worker_count_summary(workers)
  let watch_summary = standing_goal_summary(model)
  let attention = professional_attention_summary(model, executions)
  section(class="town-launchpad", [
    div(class="town-launchpad-status", [
      div(class="town-launchpad-head", [
        div(class="town-launchpad-copy", [
          p(class="eyebrow", "Town Launchpad"),
          h2("Current town pulse"),
          p(
            class="summary",
            "Health, watches, review needs, book queue, and map entry stay close to the request path.",
          ),
        ]),
        div(class="town-launchpad-actions", [
          status_chip(
            "Workers online: \{workers_summary.online()}",
            "chip-neutral",
          ),
          status_chip(
            professional_attention_chip_text(attention),
            professional_attention_chip_class(attention),
          ),
          a(
            href="./viewport.html?assets=generated&v=wenyu",
            class="town-launchpad-gateway",
            "Open Wenyu Map",
          ),
        ]),
      ]),
      div(class="town-launchpad-signal-rail", [
        render_town_launchpad_signal(
          "Town health",
          professional_town_health_label(model),
          professional_town_health_detail(model),
          professional_town_health_tone(model),
        ),
        render_town_launchpad_signal(
          "Standing watches",
          watch_summary.enabled_count.to_string(),
          professional_watch_detail(watch_summary),
          "launchpad-signal-book",
        ),
        render_town_launchpad_signal(
          "Attention",
          professional_attention_label(attention),
          professional_attention_detail(attention),
          professional_attention_tone(attention),
        ),
        render_town_launchpad_signal(
          "Book queue",
          model.operator_requests.length().to_string(),
          professional_book_queue_detail(model),
          "launchpad-signal-neutral",
        ),
      ]),
    ]),
  ])
}

///|
fn render_town_launchpad_signal(
  label : String,
  value : String,
  detail : String,
  tone : String,
) -> @rabbita.Html {
  article(class="town-launchpad-signal \{tone}", [
    p(class="metric-label", label),
    div(class="town-launchpad-signal-main", [
      p(class="town-launchpad-value", value),
      p(class="town-launchpad-signal-note", detail),
    ]),
  ])
}

///|
fn professional_attention_chip_text(
  summary : ProfessionalAttentionSummary,
) -> String {
  if professional_attention_has_failed(summary) {
    "Recovery: \{summary.failed_count}"
  } else if professional_attention_has_review(summary) {
    "Review: \{summary.review_count}"
  } else {
    "Attention clear"
  }
}

///|
fn professional_attention_chip_class(
  summary : ProfessionalAttentionSummary,
) -> String {
  if professional_attention_has_failed(summary) ||
    professional_attention_has_review(summary) {
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
    "launchpad-signal-alert"
  } else {
    "launchpad-signal-calm"
  }
}

///|
fn professional_town_health_detail(model : Model) -> String {
  if mayor_recovery_active(model) {
    "Review load first"
  } else if model.paused {
    "Updates paused"
  } else {
    "Loop stable"
  }
}

///|
fn professional_watch_detail(summary : StandingGoalSummary) -> String {
  if summary.enabled_count == 0 {
    "Ready to save"
  } else if summary.disabled_count > 0 {
    "\{summary.disabled_count} paused"
  } else {
    "Cadence active"
  }
}

///|
fn professional_attention_label(
  summary : ProfessionalAttentionSummary,
) -> String {
  if professional_attention_has_failed(summary) {
    "Failed"
  } else if professional_attention_has_review(summary) {
    "Review"
  } else {
    "Clear"
  }
}

///|
fn professional_attention_tone(
  summary : ProfessionalAttentionSummary,
) -> String {
  if professional_attention_has_failed(summary) {
    "launchpad-signal-alert"
  } else if professional_attention_has_review(summary) {
    "launchpad-signal-review"
  } else {
    "launchpad-signal-calm"
  }
}

///|
fn professional_attention_detail(
  summary : ProfessionalAttentionSummary,
) -> String {
  if professional_attention_has_failed(summary) {
    "\{summary.failed_count} recover"
  } else if professional_attention_has_review(summary) {
    "\{summary.review_count} review"
  } else {
    "No blockers"
  }
}

///|
fn professional_book_queue_detail(model : Model) -> String {
  let template_requests = live_autonomy_operator_view(
      model,
      fallback_active_workers=0,
    ).template_request_count
  if template_requests > 0 {
    "\{template_requests} setup"
  } else {
    "No setup pending"
  }
}
