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
    class="viewport-page viewport-mode-\{viewport_mode_slug(model.viewport_mode)}",
    [
      header(class="viewport-hud", [
        div(class="viewport-title", [
          p(class="eyebrow", "MoonTown Viewport"),
          h1(context.scene.title),
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
fn render_standalone_viewport_actions(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  render_viewport_command_bar(dispatch, model)
}
