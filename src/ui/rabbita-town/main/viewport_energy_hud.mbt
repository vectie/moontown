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
  div(
    class="viewport-energy-metrics",
    attrs=@html.Attrs::build().aria_label("Town pulse"),
    [
      render_viewport_energy_metric(
        "Agents",
        workers_for_model(model).length().to_string(),
        "agents",
      ),
      render_viewport_energy_metric(
        "Energy",
        model.energy.to_string(),
        "energy",
      ),
      render_viewport_energy_metric(
        "Budget",
        model.budget.to_string(),
        "budget",
      ),
      render_viewport_energy_metric(
        "Pressure",
        model.pressure.to_string(),
        if model.pressure > 70 {
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
