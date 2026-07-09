///|
fn render_request_desk(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  section(class="request-desk", [
    div(class="request-desk-head", [
      div([
        p(class="eyebrow", "Request Desk"),
        h2("Start the next safe job"),
        p(
          class="summary",
          "Create a standing watch or queue a PDF evidence book only when there is concrete work to add.",
        ),
      ]),
    ]),
    render_request_desk_workspace(dispatch, model),
  ])
}
