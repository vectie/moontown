///|
fn render_artifact_grid_or_empty(
  items : Array[@rabbita.Html],
  empty_title : String,
  empty_detail : String,
) -> @rabbita.Html {
  div(
    class="handoff-artifact-grid",
    if items.is_empty() {
      [
        article(class="viewport-output-empty", [
          h2(empty_title),
          p(empty_detail),
        ]),
      ]
    } else {
      items
    },
  )
}
