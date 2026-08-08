///|
/// Browser-owned timer state makes the simulation clock a singleton across
/// pause/resume transitions and development remounts. Updating the callback is
/// safe while a timeout is pending; the timeout always delivers into the
/// newest Rabbita scheduler.
extern "js" fn browser_schedule_simulation_tick(callback : () -> Unit) -> Unit =
  #| callback => {
  #|   let lifecycle = globalThis.__moontownSimulationTickLifecycle;
  #|   if (!lifecycle) {
  #|     lifecycle = { timer: null, callback: null, generation: 0 };
  #|     globalThis.__moontownSimulationTickLifecycle = lifecycle;
  #|   }
  #|   lifecycle.callback = callback;
  #|   if (lifecycle.timer !== null) return;
  #|   const generation = ++lifecycle.generation;
  #|   lifecycle.timer = globalThis.setTimeout(() => {
  #|     if (globalThis.__moontownSimulationTickLifecycle !== lifecycle ||
  #|         lifecycle.generation !== generation) return;
  #|     lifecycle.timer = null;
  #|     const deliver = lifecycle.callback;
  #|     lifecycle.callback = null;
  #|     if (typeof deliver === "function") deliver();
  #|   }, 1200);
  #| }

///|
extern "js" fn browser_cancel_simulation_tick() -> Unit =
  #| () => {
  #|   const lifecycle = globalThis.__moontownSimulationTickLifecycle;
  #|   if (!lifecycle) return;
  #|   lifecycle.generation += 1;
  #|   if (lifecycle.timer !== null) {
  #|     globalThis.clearTimeout?.(lifecycle.timer);
  #|   }
  #|   lifecycle.timer = null;
  #|   lifecycle.callback = null;
  #| }

///|
fn schedule_tick(dispatch : Dispatch[Msg]) -> Cmd {
  @cmd.custom_cmd(scheduler => {
    browser_schedule_simulation_tick(fn() { scheduler.add(dispatch(Tick)) })
  })
}

///|
fn cancel_scheduled_tick() -> Cmd {
  @cmd.custom_cmd(_scheduler => browser_cancel_simulation_tick())
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
    TownLifeStorageChanged => town_life_storage_changed_update(model)
    Tick => tick_update(dispatch, model)
    TogglePause => toggle_pause_update(dispatch, model)
    Step => step_update(model)
    SelectWorker(worker_id) =>
      model_only_update({ ..model, selection: Worker(worker_id) })
    SelectNode(node_key) =>
      model_only_update({ ..model, selection: Node(node_key) })
    SelectOverview => model_only_update({ ..model, selection: Overview })
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
    SetEnergyTool(tool) =>
      // Picking a build/demolish tool means the next click should build, not
      // walk — drop walk mode so the two never fight over the same tap.
      model_only_update({ ..model, energy_tool: tool, walk_mode: false })
    ToggleEnergyBoard => {
      let opening = !model.energy_board_open
      let next = if opening {
        {
          ..model,
          energy_board_open: true,
          energy_selected_building: None,
          selection: Overview,
          energy_first_agent_open: false,
          resident_explorer_open: false,
          town_chronicle_open: false,
        }
      } else {
        { ..model, energy_board_open: false }
      }
      if opening {
        town_life_commit(track_event(next, "board_open", ""))
      } else {
        model_only_update(next)
      }
    }
    ToggleEnergyStatus =>
      model_only_update({
        ..model,
        energy_status_open: !model.energy_status_open,
      })
    OpenEnergyGuide =>
      town_life_commit(
        track_event(
          {
            ..model,
            energy_board_open: false,
            energy_guide_open: true,
            energy_intro_open: false,
            resident_explorer_open: false,
            town_chronicle_open: false,
          },
          "guide_open",
          "",
        ),
      )
    CloseEnergyGuide => model_only_update({ ..model, energy_guide_open: false })
    OpenEnergyReset =>
      model_only_update({
        ..model,
        energy_board_open: false,
        energy_reset_open: true,
        resident_explorer_open: false,
        town_chronicle_open: false,
      })
    CloseEnergyReset => model_only_update({ ..model, energy_reset_open: false })
    CloseEnergyIntro => {
      browser_mark_energy_valley_intro_seen()
      model_only_update({ ..model, energy_intro_open: false })
    }
    OpenEnergyRequest =>
      model_only_update({
        ..close_town_transient_surfaces(model),
        energy_board_open: false,
        energy_request_open: true,
        selection: Overview,
        request_composer: StandingWatchComposer,
      })
    OpenEnergyRequestForAgent(contact_id) => {
      let contact = phone_contact_by_id(model, contact_id)
      match resident_runtime_agent_by_id(model, contact_id) {
        Some(agent) => {
          let task = resident_runtime_task_for_agent(model, agent)
          model_only_update({
            ..close_town_transient_surfaces(model),
            energy_request_open: true,
            selection: Overview,
            request_composer: StandingWatchComposer,
            request_title: resident_request_title(agent),
            request_prompt: resident_request_prompt(model, agent, task),
            request_book_id: resident_request_book_id(model, agent, task),
            request_submitting: false,
            request_status: "Ready to submit a standing watch request.",
          })
        }
        None =>
          model_only_update({
            ..close_town_transient_surfaces(model),
            energy_request_open: true,
            selection: Overview,
            request_composer: StandingWatchComposer,
            request_title: "基于 \{contact.name} 的上下文创建真实工作",
            request_prompt: "来自谷光手机联系人 \{contact.name}（\{contact.id}）的上下文：\{contact.greeting}\n\n请建立一项可审阅、可追踪结果页的真实工作。此表单保存的是持续观察请求；MoonTown 调度策略会选择最终执行 Agent，联系人只是上下文来源，不代表定向派单。",
            request_submitting: false,
            request_status: "Ready to submit a standing watch request.",
          })
      }
    }
    CloseEnergyRequest =>
      model_only_update({ ..model, energy_request_open: false })
    ToggleResidentExplorer => {
      let opening = !model.resident_explorer_open
      if opening {
        model_only_update({
          ..close_town_transient_surfaces(model),
          resident_explorer_open: true,
          selection: Overview,
        })
      } else {
        model_only_update({ ..model, resident_explorer_open: false })
      }
    }
    ResidentSearch(query) =>
      model_only_update({ ..model, resident_query: query })
    ToggleTownChronicle => {
      let opening = !model.town_chronicle_open
      if opening {
        model_only_update({
          ..close_town_transient_surfaces(model),
          town_chronicle_open: true,
          selection: Overview,
        })
      } else {
        model_only_update({ ..model, town_chronicle_open: false })
      }
    }
    EnergyResetCurrent => {
      let current = town_life_refresh_model_from_storage(model)
      let posts = knowledge_posts_after_map_reset(current.posts)
      let next = {
        ..town_life_reset_map_bound_state(current, posts),
        player_motion: None,
        knowledge_dialog_open: false,
        knowledge_target_building: "",
        knowledge_target_site_id: "",
        knowledge_draft_topic: "",
      }
      let (next, written) = persist_town_life_model_result(next)
      energy_reset_after_persistence(
        next, written, false, browser_reset_energy_valley,
      )
    }
    EnergyGenerateNew => {
      let current = town_life_refresh_model_from_storage(model)
      let posts = knowledge_posts_after_map_reset(current.posts)
      let next = {
        ..town_life_reset_map_bound_state(current, posts),
        player_motion: None,
        knowledge_dialog_open: false,
        knowledge_target_building: "",
        knowledge_target_site_id: "",
        knowledge_draft_topic: "",
      }
      let (next, written) = persist_town_life_model_result(next)
      energy_reset_after_persistence(
        next, written, true, browser_reset_energy_valley,
      )
    }
    EnergyCanvasClick(screen_x, screen_y) =>
      energy_canvas_click_routed(model, screen_x, screen_y)
    OpenEnergyBuilding(building_id) => open_building_update(model, building_id)
    OpenEcosystemAttention(cooldown_key, interaction_target) =>
      ecosystem_open_attention_update(model, cooldown_key, interaction_target)
    CloseEnergyInspector =>
      model_only_update({ ..model, energy_selected_building: None })
    SetDashboardSection(section) =>
      model_only_update(set_dashboard_section_model(model, section))
    SetRequestComposer(focus) =>
      model_only_update(set_request_composer_model(model, focus))
    SelectAgent(agent_id) =>
      model_only_update({
        ..close_town_transient_surfaces(model),
        selection: Agent(agent_id),
      })
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
    AvatarDraftName(value) =>
      model_only_update({ ..model, avatar_draft_name: value })
    AvatarDraftPersona(value) =>
      model_only_update({ ..model, avatar_draft_persona: value })
    AvatarDraftColor(index) =>
      model_only_update({ ..model, avatar_draft_color: index })
    AvatarWizardNext =>
      if model.avatar_wizard_step < 2 {
        model_only_update({
          ..model,
          avatar_wizard_step: model.avatar_wizard_step + 1,
        })
      } else {
        model_only_update(model)
      }
    AvatarWizardBack =>
      if model.avatar_wizard_step > 0 {
        model_only_update({
          ..model,
          avatar_wizard_step: model.avatar_wizard_step - 1,
        })
      } else {
        model_only_update(model)
      }
    AvatarCreate => avatar_create_update(model)
    AvatarOpenEditor => avatar_open_editor_update(model)
    ToggleWalkMode => {
      let next = { ..model, walk_mode: !model.walk_mode }
      town_life_commit(
        track_event(
          next,
          "walk_mode",
          if next.walk_mode {
            "on"
          } else {
            "off"
          },
        ),
      )
    }
    TogglePlayerFollow =>
      model_only_update({ ..model, player_follow: !model.player_follow })
    PlayerStepDirection(dx, dy) => player_step_direction_update(model, dx, dy)
    PlayerStepTo(tx, ty) => player_step_to_update(model, tx, ty)
    TogglePhone => phone_toggle_update(model)
    PhoneSelectContact(contact) =>
      model_only_update({ ..model, phone_contact: contact })
    PhoneDraft(value) => model_only_update({ ..model, phone_draft: value })
    PhoneSend => town_life_commit(phone_send_model(model))
    ToggleSquare => square_toggle_update(model)
    OpenKnowledgeDialog(post_id) =>
      model_only_update(knowledge_open_dialog_model(model, post_id))
    CloseKnowledgeDialog =>
      model_only_update({ ..model, knowledge_dialog_open: false })
    KnowledgeDraftTopic(value) =>
      model_only_update({ ..model, knowledge_draft_topic: value })
    ConfirmKnowledgeTopic =>
      town_life_commit(knowledge_confirm_topic_model(model))
    PublishBuilding(post_id) =>
      town_life_commit(knowledge_publish_model(model, post_id))
    CollectBuilding(post_id) =>
      town_life_commit(
        knowledge_collect_model(
          town_life_refresh_model_from_storage(model),
          post_id,
        ),
      )
    ToggleOps => ops_toggle_update(model)
    SetOpsTab(index) => model_only_update({ ..model, ops_tab: index })
    OpsGenerateReport => ops_generate_report_update(model)
    ToggleMetro =>
      town_life_commit(
        track_event(
          { ..model, metro_visible: !model.metro_visible },
          "metro_toggle",
          "",
        ),
      )
    DailyCheckin => daily_checkin_update(model)
    CloseLifeToast => model_only_update({ ..model, life_toast: "" })
    ToggleMapLab =>
      model_only_update({ ..model, map_lab_open: !model.map_lab_open })
    CloseMapLab => model_only_update({ ..model, map_lab_open: false })
    ToggleMapLabLayer(layer) =>
      model_only_update({
        ..model,
        map_lab_layers: map_lab_toggle_layer(model.map_lab_layers, layer),
      })
    SelectMapLabEntity(entity_id) =>
      model_only_update({ ..model, map_lab_selected_id: entity_id })
    SetMapLabQuery(query) =>
      model_only_update({ ..model, map_lab_query: query })
    _ => model_only_update(model)
  }
}

///|
/// Navigation is an effect of a verified durable reset, never merely of the
/// user's click. A failed quota/readback check leaves the reset state in memory
/// so the user can recover storage and retry without losing the current page.
fn energy_reset_after_persistence(
  next : Model,
  written : Bool,
  regenerate : Bool,
  navigate : (Bool) -> Unit,
) -> (Cmd, Model) {
  if written {
    navigate(regenerate)
    model_only_update(next)
  } else {
    model_only_update({
      ..next,
      energy_toast: "保存失败：浏览器未能写入小镇状态。页面已保留，请清理存储空间后重试。",
    })
  }
}

///|
