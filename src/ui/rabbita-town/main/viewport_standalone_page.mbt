///|
fn render_standalone_viewport_page(
  dispatch : Dispatch[Msg],
  model : Model,
  context : RenderSceneContext,
) -> @rabbita.Html {
  let viewport_body = match model.viewport_mode {
    ViewMode =>
      render_viewport_view_body(
        dispatch,
        model,
        context.scene,
        context.workers,
        context.executions,
        context.selected_node_key,
        context.selected_worker_id,
      )
    EditorMode =>
      render_viewport_editor_body(
        dispatch,
        model,
        context.scene,
        context.workers,
        context.executions,
        context.selected_node_key,
        context.selected_worker_id,
      )
    OutputMode => render_viewport_output_body(model)
  }
  section(
    class="viewport-page viewport-mode-\{viewport_mode_slug(model.viewport_mode)}\{viewport_detail_class(model)}",
    [
      header(class="viewport-hud", [
        div(class="viewport-title", [
          div(class="viewport-title-copy", [
            h1("MoonTown · Energy Valley"),
            p(class="eyebrow", "WENYU VALLEY · CHANGPING"),
          ]),
          div(class="viewport-title-time", [
            span(class="viewport-title-clock", real_time_label()),
            span(real_phase_label()),
          ]),
          p(
            class="viewport-mode-subtitle",
            viewport_mode_summary(model.viewport_mode),
          ),
        ]),
        render_standalone_viewport_actions(dispatch, model),
      ]),
      viewport_body,
    ],
  )
}

///|
fn viewport_detail_class(model : Model) -> String {
  match model.selection {
    Overview => ""
    _ => " viewport-detail-open"
  }
}

///|
fn render_standalone_viewport_actions(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  render_viewport_command_bar(dispatch, model)
}
