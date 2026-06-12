///|
fn render_module_detail(label : String, value : String) -> @rabbita.Html {
  div(class="module-detail-card", [
    span(class="module-detail-label", label),
    p(value),
  ])
}

///|
fn render_module_detail_grid(details : Array[@rabbita.Html]) -> @rabbita.Html {
  div(class="module-detail-grid", details)
}
