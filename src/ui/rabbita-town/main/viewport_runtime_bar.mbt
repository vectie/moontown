///|
fn runtime_stat_chip(
  label : String,
  value : Int32,
  class_name : String,
) -> @rabbita.Html {
  article(class="runtime-stat \{class_name}", [
    p(class="metric-label", label),
    p(class="runtime-stat-value", value.to_string()),
  ])
}
