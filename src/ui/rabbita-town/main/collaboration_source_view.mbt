///|
fn render_source_picker(
  dispatch : Dispatch[Msg],
  state : @collaboration.Client,
  participant : @collaboration.Participant,
) -> @rabbita.Html {
  div(class="request-desk-stack", [
    h3("Observed source paths · " + participant.book_id),
    p(
      "Selection records paths only. Explicit Save draft and capture sources captures current bytes. Up to 16 files per Book and 8 MiB total.",
    ),
    collaboration_field(
      "collaboration-source-filter",
      "Search observed paths",
      state.source_filter,
      state.busy(),
      value => dispatch(CollaborationEdit("source_filter", value)),
    ),
    match state.source_listing {
      None => p("No source observation loaded yet. Browse or retry this Book.")
      Some(listing) =>
        div([
          p(listing.detail),
          p(
            state.visible_source_paths().length().to_string() +
            " matching observed paths; " +
            listing.paths.length().to_string() +
            " eligible paths observed.",
          ),
          div(
            class="request-actions",
            state
            .visible_source_paths()
            .map(path => {
              let selected = participant.source_paths.contains(path)
              button(
                attrs=@html.Attrs::build()
                  .disabled(state.busy())
                  .aria_pressed(if selected { "true" } else { "false" }),
                on_click=dispatch(CollaborationToggleSource(path)),
                (if selected { "Remove: " } else { "Select: " }) + path,
              )
            }),
          ),
        ])
    },
    p(
      "Selected paths (not yet captured): " +
      participant.source_paths.join(", "),
    ),
  ])
}
