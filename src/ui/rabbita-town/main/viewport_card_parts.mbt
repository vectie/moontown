///|
fn render_memory_strip(
  label : String,
  detail : String,
  strip_class? : String = "memory-strip",
) -> @rabbita.Html {
  div(class=strip_class, [span(label), p(detail)])
}

///|
fn render_metric_track(
  fill : Int,
  tone? : String = "tone-energy",
) -> @rabbita.Html {
  let fill_style = ["width: \{fill}%"]
  div(class="metric-track", [
    div(class="metric-fill \{tone}", style=fill_style, no_children()),
  ])
}
