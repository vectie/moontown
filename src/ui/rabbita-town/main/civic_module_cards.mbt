///|
fn render_module_metric(label : String, value : String) -> @rabbita.Html {
  div(class="module-metric", [
    span(class="module-metric-label", label),
    p(value),
  ])
}

///|
fn render_module_metric_grid(
  worker_label : String,
  queue_pressure : Int,
  health : Int,
) -> @rabbita.Html {
  div(class="module-metric-grid", [
    render_module_metric("Worker", worker_label),
    render_module_metric("Queue", "\{queue_pressure}%"),
    render_module_metric("Health", "\{health}%"),
  ])
}

///|
fn render_module_next_action(next_action : String) -> @rabbita.Html {
  p(class="module-next-action", "Next: \{next_action}")
}

///|
fn render_module_signal(
  signal_class : String,
  signal : String,
) -> @rabbita.Html {
  span(class="module-signal \{signal_class}", signal)
}

///|
fn render_civic_modules(model : Model) -> @rabbita.Html {
  section(class="civic-modules", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Wenyu Valley Modules"),
      h2(
        if mayor_recovery_active(model) {
          "Recovery Patrol"
        } else {
          "District Systems"
        },
      ),
    ]),
    div(class="civic-module-grid", [
      render_town_shell_module_card(model),
      render_vitality_dashboard_module_card(model),
      render_resident_twins_module_card(model),
      render_policy_hall_module_card(model),
      render_contest_express_module_card(model),
      render_social_square_module_card(model),
      render_talent_avenue_module_card(model),
      render_ai_garden_module_card(model),
      render_physical_bridge_module_card(model),
    ]),
  ])
}
