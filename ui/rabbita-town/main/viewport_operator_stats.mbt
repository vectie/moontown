///|
fn render_operator_stat(
  label : String,
  value : String,
  detail : String,
  tone : String,
) -> @rabbita.Html {
  article(class="operator-stat operator-stat-\{tone}", [
    p(class="metric-label", label),
    p(class="operator-stat-value", value),
    p(class="operator-stat-detail", detail),
  ])
}
