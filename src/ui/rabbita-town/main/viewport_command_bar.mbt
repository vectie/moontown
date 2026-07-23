///|
fn viewport_runtime_status_label(model : Model) -> String {
  match runtime_availability(model) {
    DemoRuntime => if model.paused { "Demo paused" } else { "Demo" }
    ConnectingRuntime => "Connecting"
    OfflineRuntime => "Town offline"
    LiveRuntime => "Live town"
  }
}

///|
fn viewport_runtime_status_tone(model : Model) -> String {
  match runtime_availability(model) {
    DemoRuntime => "chip-neutral"
    ConnectingRuntime => "chip-clock"
    OfflineRuntime => "chip-alert"
    LiveRuntime => "chip-live"
  }
}

///|
fn viewport_demo_controls_visible(model : Model) -> Bool {
  model.state_source == DemoSimulation
}

///|
fn viewport_daemon_status_visible(model : Model) -> Bool {
  if runtime_availability(model) is LiveRuntime {
    match model.daemon_snapshot {
      Some(_) => true
      None => false
    }
  } else {
    false
  }
}

///|
fn viewport_module_status_label() -> String {
  "Modules \{wenyu_clean_module_count()}/\{wenyu_module_count()} · v\{wenyu_modules_version()}"
}

///|
fn render_viewport_zoom_button(
  dispatch : Dispatch[Msg],
  direction : String,
) -> @rabbita.Html {
  let zoom_in = direction == "in"
  button(
    class="control-button viewport-zoom-button viewport-zoom-\{direction}",
    on_click=dispatch(ViewportControlNoop),
    attrs=@html.Attrs::build().aria_label(
      if zoom_in {
        "Zoom in"
      } else {
        "Zoom out"
      },
    ),
    if zoom_in {
      "+"
    } else {
      "-"
    },
  )
}

///|
fn render_viewport_command_bar(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let actions : Array[@rabbita.Html] = [
    render_viewport_energy_metrics(model),
    render_viewport_mode_switch(dispatch, model),
    status_chip(
      viewport_runtime_status_label(model),
      viewport_runtime_status_tone(model),
    ),
    status_chip(viewport_module_status_label(), "chip-book"),
  ]
  if viewport_daemon_status_visible(model) {
    actions.push(status_chip(daemon_tick_label(model), "chip-neutral"))
  }
  actions.push(render_viewport_zoom_button(dispatch, "out"))
  actions.push(render_viewport_zoom_button(dispatch, "in"))
  if viewport_demo_controls_visible(model) {
    actions.push(
      button(
        class="control-button viewport-demo-control",
        on_click=dispatch(TogglePause),
        if model.paused {
          "Resume"
        } else {
          "Pause"
        },
      ),
    )
    actions.push(
      button(
        class="control-button viewport-demo-control",
        on_click=dispatch(Step),
        "Step",
      ),
    )
  }
  actions.push(render_viewport_operations_link())
  div(class="viewport-actions", actions)
}
