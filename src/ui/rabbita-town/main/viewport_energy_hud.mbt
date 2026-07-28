///|
fn render_viewport_energy_metric(
  label : String,
  value : String,
  tone : String,
) -> @rabbita.Html {
  div(class="viewport-energy-metric metric-\{tone}", [
    span(class="viewport-energy-value", value),
    span(class="viewport-energy-label", label),
  ])
}

///|
fn render_viewport_energy_metrics(model : Model) -> @rabbita.Html {
  let runtime = model.energy_valley_runtime
  div(
    class="viewport-energy-metrics",
    attrs=@html.Attrs::build().aria_label("Town pulse"),
    [
      render_viewport_energy_metric(
        "Agents",
        energy_valley_runtime_active_agents(runtime).length().to_string(),
        "agents",
      ),
      render_viewport_energy_metric(
        "Open work",
        energy_valley_runtime_open_task_count(runtime).to_string(),
        "energy",
      ),
      render_viewport_energy_metric(
        "Review",
        energy_valley_runtime_task_count(runtime, "waiting_review").to_string(),
        "budget",
      ),
      render_viewport_energy_metric(
        "Blocked",
        (energy_valley_runtime_task_count(runtime, "blocked") +
        energy_valley_runtime_task_count(runtime, "failed")).to_string(),
        if energy_valley_runtime_task_count(runtime, "blocked") > 0 ||
          energy_valley_runtime_task_count(runtime, "failed") > 0 {
          "alert"
        } else {
          "pressure"
        },
      ),
    ],
  )
}

///|
fn render_viewport_operations_link() -> @rabbita.Html {
  a(class="viewport-operations-link", href="./operations.html", "Operations")
}
