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
          p(class="eyebrow", "Moontown Viewport"),
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
  div(class="viewport-actions", [
    render_viewport_mode_switch(dispatch, model),
    status_chip(if model.paused { "Paused" } else { "Live" }, "chip-live"),
    status_chip("Local time \{real_time_label()}", "chip-clock"),
    status_chip(daemon_tick_label(model), "chip-neutral"),
    status_chip(
      "Modules \{wenyu_clean_module_count()}/\{wenyu_module_count()} · v\{wenyu_modules_version()}",
      "chip-book",
    ),
    button(
      class="control-button viewport-zoom-button viewport-zoom-out",
      on_click=dispatch(ViewportControlNoop),
      "Zoom Out",
    ),
    button(
      class="control-button viewport-zoom-button viewport-zoom-in",
      on_click=dispatch(ViewportControlNoop),
      "Zoom In",
    ),
    button(
      class="control-button",
      on_click=dispatch(TogglePause),
      if model.paused {
        "Resume"
      } else {
        "Pause"
      },
    ),
    button(class="control-button", on_click=dispatch(Step), "Step"),
  ])
}
