///|
fn schedule_tick(dispatch : Dispatch[Msg]) -> Cmd {
  @rabbita.delay(dispatch(Tick), 1200)
}

///|
fn update(dispatch : Dispatch[Msg], msg : Msg, model : Model) -> (Cmd, Model) {
  match form_model_for_msg(model, msg) {
    Some(next) => model_only_update(next)
    None => update_non_form_message(dispatch, msg, model)
  }
}

///|
fn update_non_form_message(
  dispatch : Dispatch[Msg],
  msg : Msg,
  model : Model,
) -> (Cmd, Model) {
  match msg {
    ViewportControlNoop => model_only_update(model)
    Tick => tick_update(dispatch, model)
    TogglePause => toggle_pause_update(dispatch, model)
    Step => step_update(model)
    SelectWorker(worker_id) =>
      model_only_update({ ..model, selection: Worker(worker_id) })
    SelectNode(node_key) =>
      model_only_update({ ..model, selection: Node(node_key) })
    SelectOverview => model_only_update({ ..model, selection: Overview })
    SetViewportMode(viewport_mode) =>
      model_only_update(set_viewport_mode_model(model, viewport_mode))
    SetEnergyWeather(weather) =>
      model_only_update({
        ..model,
        energy_weather: weather,
        energy_weather_auto: false,
      })
    ToggleEnergyWeatherAuto =>
      model_only_update({
        ..model,
        energy_weather_auto: !model.energy_weather_auto,
      })
    SetEnergyTimeScale(scale) =>
      model_only_update({ ..model, energy_time_scale: scale })
    SetEnergyTool(tool) => model_only_update({ ..model, energy_tool: tool })
    ToggleEnergyBoard =>
      model_only_update({ ..model, energy_board_open: !model.energy_board_open })
    OpenEnergyGuide =>
      model_only_update({
        ..model,
        energy_board_open: false,
        energy_guide_open: true,
        energy_intro_open: false,
      })
    CloseEnergyGuide => model_only_update({ ..model, energy_guide_open: false })
    OpenEnergyReset =>
      model_only_update({
        ..model,
        energy_board_open: false,
        energy_reset_open: true,
      })
    CloseEnergyReset => model_only_update({ ..model, energy_reset_open: false })
    CloseEnergyIntro => {
      browser_mark_energy_valley_intro_seen()
      model_only_update({ ..model, energy_intro_open: false })
    }
    OpenEnergyRequest =>
      model_only_update({
        ..model,
        energy_board_open: false,
        energy_request_open: true,
        request_composer: StandingWatchComposer,
      })
    CloseEnergyRequest =>
      model_only_update({ ..model, energy_request_open: false })
    EnergyResetCurrent => {
      browser_reset_energy_valley(false)
      model_only_update(model)
    }
    EnergyGenerateNew => {
      browser_reset_energy_valley(true)
      model_only_update(model)
    }
    EnergyCanvasClick(screen_x, screen_y) => {
      let next = energy_valley_canvas_click_model(model, screen_x, screen_y)
      persist_energy_valley_model(next)
      model_only_update(next)
    }
    OpenEnergyBuilding(building_id) =>
      model_only_update(
        energy_valley_open_registered_building_model(model, building_id),
      )
    CloseEnergyInspector =>
      model_only_update({ ..model, energy_selected_building: None })
    SetDashboardSection(section) =>
      model_only_update(set_dashboard_section_model(model, section))
    SetRequestComposer(focus) =>
      model_only_update(set_request_composer_model(model, focus))
    SubmitOperatorRequest => submit_operator_request_update(dispatch, model)
    SubmitBookTemplateRequest =>
      submit_book_template_request_update(dispatch, model)
    OperatorRequestSubmitted(raw) => operator_request_result_update(raw, model)
    BookTemplateRequestSubmitted(raw) =>
      book_template_request_result_update(raw, model)
    ResearchHandoffInspected(raw) =>
      match model.research_handoff {
        LoadingResearchHandoff(request) =>
          model_only_update({
            ..model,
            research_handoff: resolve_research_handoff_response(request, raw),
          })
        _ => model_only_update(model)
      }
    StartResearchHandoff =>
      match model.research_handoff {
        ReadyResearchHandoff(request, handoff) =>
          (
            execute_research_handoff_cmd(dispatch, request, "start"),
            {
              ..model,
              research_handoff: ExecutingResearchHandoff(
                request, handoff, "start",
              ),
            },
          )
        _ => model_only_update(model)
      }
    ReconcileResearchHandoff =>
      match model.research_handoff {
        SettledResearchHandoff(request, handoff, reply) =>
          if reply.callback_status == "pending-reconcile" {
            (
              execute_research_handoff_cmd(dispatch, request, "reconcile"),
              {
                ..model,
                research_handoff: ExecutingResearchHandoff(
                  request, handoff, "reconcile",
                ),
              },
            )
          } else {
            model_only_update(model)
          }
        _ => model_only_update(model)
      }
    ResearchHandoffExecuted(raw) =>
      match model.research_handoff {
        ExecutingResearchHandoff(request, handoff, action) =>
          model_only_update({
            ..model,
            research_handoff: resolve_research_handoff_execution_response(
              request, handoff, action, raw,
            ),
          })
        _ => model_only_update(model)
      }
    MoonFlowReceiverInspected(raw) =>
      match model.moonflow_receiver {
        LoadingMoonFlowReceiver(request) =>
          model_only_update({
            ..model,
            moonflow_receiver: resolve_moonflow_receiver_inspection(
              request, raw,
            ),
          })
        _ => model_only_update(model)
      }
    StartMoonFlowReceiver =>
      match model.moonflow_receiver {
        ReadyMoonFlowReceiver(request, intake, status) =>
          (
            execute_moonflow_receiver_cmd(dispatch, request, intake, "start"),
            {
              ..model,
              moonflow_receiver: ExecutingMoonFlowReceiver(
                request, intake, status, "start",
              ),
            },
          )
        _ => model_only_update(model)
      }
    ReconcileMoonFlowReceiver =>
      match model.moonflow_receiver {
        SettledMoonFlowReceiver(request, intake, status, Some(reply)) =>
          if !reply.ok && status.status == "pending" {
            (
              execute_moonflow_receiver_cmd(
                dispatch, request, intake, "reconcile",
              ),
              {
                ..model,
                moonflow_receiver: ExecutingMoonFlowReceiver(
                  request, intake, status, "reconcile",
                ),
              },
            )
          } else {
            model_only_update(model)
          }
        _ => model_only_update(model)
      }
    MoonFlowReceiverSettled(raw) =>
      match model.moonflow_receiver {
        ExecutingMoonFlowReceiver(request, intake, status, action) =>
          model_only_update({
            ..model,
            moonflow_receiver: resolve_moonflow_receiver_settlement(
              request, intake, status, action, raw,
            ),
          })
        _ => model_only_update(model)
      }
    _ => model_only_update(model)
  }
}

///|
