///|
fn render_request_desk(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  section(class="request-desk", [
    div(class="request-desk-head", [
      div(class="request-desk-title", [
        p(class="eyebrow", "Request Desk"),
        h2("Requests"),
      ]),
      render_request_shortcuts(dispatch, model),
    ]),
    render_request_desk_workspace(dispatch, model),
  ])
}
