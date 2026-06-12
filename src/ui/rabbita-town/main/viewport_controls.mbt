///|
fn render_strategy_button(
  dispatch : Dispatch[Msg],
  current : Strategy,
  strategy : Strategy,
) -> @rabbita.Html {
  let active = current == strategy
  let class_name = "strategy-button" + class_suffix_when(active, " active")
  button(
    class=class_name,
    on_click=dispatch(SetStrategy(strategy)),
    strategy_label(strategy),
  )
}

///|
fn render_controls(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let control_status = control_status_chip_for_model(model)
  let action_label = if model.paused { "Resume" } else { "Pause" }
  section(class="control-hub", [
    div(class="control-strip", [
      status_chip(control_status.text, control_status.class_name),
      status_chip("Local time \{real_time_label()}", "chip-clock"),
      status_chip(daemon_tick_label(model), "chip-neutral"),
      status_chip(daemon_heartbeat_label(model), "chip-neutral"),
      status_chip("Mode: \{strategy_label(model.strategy)}", "chip-book"),
      status_chip(
        "State sources: \{state_source_options().length()}",
        "chip-neutral",
      ),
      button(
        class="control-button",
        on_click=dispatch(ToggleStateSource),
        "Switch Source",
      ),
      button(
        class="control-button",
        on_click=dispatch(TogglePause),
        action_label,
      ),
      button(class="control-button", on_click=dispatch(Step), "Step"),
    ]),
    div(class="strategy-strip", [
      render_strategy_button(dispatch, model.strategy, Strategy::Balanced),
      render_strategy_button(dispatch, model.strategy, Strategy::Throughput),
      render_strategy_button(dispatch, model.strategy, Strategy::Recovery),
      button(
        class="action-button",
        on_click=dispatch(InjectBudget),
        "Inject Budget",
      ),
      button(
        class="action-button",
        on_click=dispatch(RelieveQueue),
        "Relieve Queue",
      ),
      button(
        class="action-button",
        on_click=dispatch(StabilityDrill),
        "Stability Drill",
      ),
    ]),
  ])
}
