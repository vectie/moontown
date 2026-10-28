///|
fn render_request_desk(
  dispatch : Dispatch[Msg],
  model : Model,
  compact~ : Bool = false,
) -> @rabbita.Html {
  section(class="request-desk", [
    if compact {
      @html.nothing
    } else {
      div(class="request-desk-head", [h2("工作与成果")])
    },
    if compact {
      @html.nothing
    } else {
      render_work_workspace_tabs(dispatch, model)
    },
    if model.request_composer is (ResultsComposer | AttentionComposer) {
      @html.nothing
    } else {
      render_request_shortcuts(dispatch, model)
    },
    render_request_desk_workspace(dispatch, model),
  ])
}
