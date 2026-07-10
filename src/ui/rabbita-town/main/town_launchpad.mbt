///|
fn render_town_launchpad(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  scene : @ui.SceneRenderModel,
  alerts : Array[String],
) -> @rabbita.Html {
  let workers_summary = worker_count_summary(workers)
  let watch_summary = standing_goal_summary(model)
  let attention = professional_attention_summary(model, executions)
  section(class="town-launchpad", [
    div(class="town-launchpad-status", [
      div(class="town-launchpad-head", [
        div(class="town-launchpad-copy", [
          p(class="eyebrow", "Moontown"),
          h1(scene.title),
        ]),
        div(class="town-launchpad-actions", [
          render_town_launchpad_alert_chip(alerts, model),
          status_chip(
            town_worker_chip_label(model, workers_summary.online()),
            "chip-neutral",
          ),
          status_chip(
            professional_attention_chip_text(attention),
            professional_attention_chip_class(attention),
          ),
          a(
            href="./viewport.html?assets=generated&v=wenyu",
            class="town-launchpad-gateway",
            "Map",
          ),
        ]),
      ]),
      render_town_runtime_notice(model),
      div(class="town-launchpad-signal-rail", [
        render_town_launchpad_signal(
          "Health",
          professional_town_health_label(model),
          professional_town_health_detail(model),
          professional_town_health_tone(model),
        ),
        render_town_launchpad_signal(
          "Watches",
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
          "Books",
          professional_book_queue_count(model).to_string(),
          professional_book_queue_detail(model),
          "launchpad-signal-neutral",
        ),
      ]),
    ]),
  ])
}

///|
fn render_town_launchpad_alert_chip(
  alerts : Array[String],
  model : Model,
) -> @rabbita.Html {
  status_chip(
    town_launchpad_alert_label(alerts, model),
    if runtime_is_unavailable(model) {
      "chip-alert"
    } else {
      alert_strip_chip_class(alerts)
    },
  )
}

///|
fn town_launchpad_alert_label(alerts : Array[String], model : Model) -> String {
  match runtime_availability(model) {
    ConnectingRuntime => "Connecting"
    OfflineRuntime => "Town offline"
    DemoRuntime => "Demo mode"
    LiveRuntime =>
      match alerts {
        [message] if message == no_active_alert_text => "Alerts clear"
        _ => "Alerts \{alerts.length()}"
      }
  }
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
    "Recover \{summary.failed_count}"
  } else if professional_attention_has_review(summary) {
    "Review \{summary.review_count}"
  } else {
    "Review clear"
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
  match runtime_availability(model) {
    ConnectingRuntime => "Connecting"
    OfflineRuntime => "Offline"
    DemoRuntime | LiveRuntime =>
      if mayor_recovery_active(model) {
        "Needs attention"
      } else if model.paused {
        "Paused"
      } else {
        "Healthy"
      }
  }
}

///|
fn professional_town_health_tone(model : Model) -> String {
  match runtime_availability(model) {
    ConnectingRuntime => "launchpad-signal-neutral"
    OfflineRuntime => "launchpad-signal-alert"
    DemoRuntime | LiveRuntime =>
      if mayor_recovery_active(model) || model.paused {
        "launchpad-signal-alert"
      } else {
        "launchpad-signal-calm"
      }
  }
}

///|
fn professional_town_health_detail(model : Model) -> String {
  match runtime_availability(model) {
    ConnectingRuntime => "Checking snapshot"
    OfflineRuntime => "No live snapshot"
    DemoRuntime => "Sample data"
    LiveRuntime =>
      if mayor_recovery_active(model) {
        "Review load first"
      } else if model.paused {
        "Updates paused"
      } else {
        "Loop stable"
      }
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
  let template_requests = professional_book_queue_count(model)
  if template_requests > 0 {
    "\{template_requests} setup"
  } else {
    "No setup pending"
  }
}

///|
fn professional_book_queue_count(model : Model) -> Int {
  let mut count = 0
  for request in model.book_template_requests {
    if request.status == "pending" || request.status == "retry" {
      count += 1
    }
  }
  count
}
