///|
fn render_town_launchpad(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  scene : @ui.SceneRenderModel,
) -> @rabbita.Html {
  let workers_summary = worker_count_summary(workers)
  let watch_summary = standing_goal_summary(model)
  let attention = professional_attention_summary(model, executions)
  let portal = town_launchpad_map_view(model, executions)
  section(class="town-launchpad", [
    div(class="town-launchpad-primary", [
      div(class="town-launchpad-status", [
        div(class="town-launchpad-head", [
          div(class="town-launchpad-copy", [
            p(class="eyebrow", "Town Launchpad"),
            h2("Current town pulse"),
            p(
              class="summary",
              "Health, watches, review needs, book work, and Wenyu map entry stay in one first-screen operating surface.",
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
          ]),
        ]),
        div(class="town-launchpad-grid", [
          render_town_launchpad_card(
            "Town health",
            professional_town_health_label(model),
            professional_town_health_detail(model),
            professional_town_health_tone(model),
          ),
          render_town_launchpad_card(
            "Standing watches",
            watch_summary.enabled_count.to_string(),
            professional_watch_detail(watch_summary),
            "launchpad-card-book",
          ),
          render_town_launchpad_card(
            "Attention",
            professional_attention_label(attention),
            professional_attention_detail(attention),
            professional_attention_tone(attention),
          ),
          render_town_launchpad_card(
            "Book queue",
            model.operator_requests.length().to_string(),
            professional_book_queue_detail(model),
            "launchpad-card-neutral",
          ),
        ]),
      ]),
      div(class="town-launchpad-map", [
        div(class="town-launchpad-map-copy", [
          p(class="eyebrow", "Wenyu Map"),
          h3("Open Wenyu Valley workspace"),
          p(
            class="summary",
            "Inspect districts, residents, standing watches, and active work in place.",
          ),
        ]),
        div(class="town-launchpad-map-stats", [
          status_chip("Scene: \{scene.title}", "chip-book"),
          status_chip("Latest: \{portal.latest_decision}", "chip-neutral"),
          status_chip("New sources: \{portal.latest_sources}", "chip-neutral"),
          status_chip("Next check: \{portal.next_check}", "chip-clock"),
          status_chip("Active work: \{portal.active_work}", "chip-neutral"),
        ]),
        a(
          href="./viewport.html?assets=generated&v=wenyu",
          class="town-launchpad-map-button",
          "Open Wenyu Map",
        ),
      ]),
    ]),
  ])
}

///|
fn render_town_launchpad_card(
  label : String,
  value : String,
  detail : String,
  tone : String,
) -> @rabbita.Html {
  article(class="town-launchpad-card \{tone}", [
    p(class="metric-label", label),
    p(class="town-launchpad-value", value),
    p(class="metric-detail", detail),
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
    "launchpad-card-alert"
  } else {
    "launchpad-card-calm"
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
    "launchpad-card-alert"
  } else if professional_attention_has_review(summary) {
    "launchpad-card-review"
  } else {
    "launchpad-card-calm"
  }
}

///|
fn professional_attention_detail(
  summary : ProfessionalAttentionSummary,
) -> String {
  if professional_attention_has_failed(summary) {
    "\{summary.failed_count} watch, book, or town work item needs recovery."
  } else if professional_attention_has_review(summary) {
    "\{summary.review_count} watch or town work item is waiting for review."
  } else {
    "No failed or review-blocked work is waiting."
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
