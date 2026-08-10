///|
/// Canonical Energy Valley product composition. Historical `viewport.html`
/// aliases route here through the same `render_scene` branch as `index.html`.
fn render_energy_valley_page(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  // Page orchestration compiles one immutable semantic frame. Both canvases,
  // the inspector, and pointer routing share this exact accepted snapshot.
  let snapshot = ecosystem_contract_town_snapshot(
    model,
    active_energy_valley_seed(),
  )
  render_energy_valley_page_with_snapshot(dispatch, model, snapshot)
}

///|
/// Composes every same-page semantic consumer from one immutable snapshot.
/// Keeping this boundary explicit prevents a status panel or inspector from
/// compiling a newer world than the Canvas scheduled by the same render.
fn render_energy_valley_page_with_snapshot(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  let intersection_preview = energy_valley_intersection_road_preview_active()
  let selected_place_id = match model.energy_selected_building {
    Some(building) =>
      town_snapshot_place_for_visual_building(snapshot, building).map(place => {
        place.id
      })
    None => None
  }
  let town_canvas_view : TownCanvasViewState = {
    tick: model.tick,
    weather: model.energy_weather,
    hour: (energy_valley_sim_minutes(model) % (24 * 60)).to_double() / 60.0,
    metro_visible: model.metro_visible,
    selected_place_id,
    selected_actor_id: town_snapshot_selected_actor_id(model.selection),
    runtime_agent_interaction_enabled: energy_valley_runtime_can_claim_active_work(
      model.energy_valley_runtime,
    ),
    intersection_preview,
    follow_enabled: model.player_follow && !intersection_preview,
    player_idle_position: player_idle_position(model),
    player_motion: model.player_motion,
  }
  let map_lab_canvas_view : MapLabCanvasViewState = {
    open: model.map_lab_open,
    layers: model.map_lab_layers.copy(),
    selected_id: model.map_lab_selected_id,
  }
  let map_lab_view : MapLabViewState = {
    open: model.map_lab_open,
    layers: model.map_lab_layers.copy(),
    selected_id: model.map_lab_selected_id,
    query: model.map_lab_query,
  }
  // The create-avatar wizard is onboarding stage zero. Treat it like the
  // later guided tasks so first-time visitors do not see the operator HUD,
  // runtime metrics, square, or operations center behind the modal.
  let onboarding = current_quest(model) is Some(_)
  let stage = quest_progress_count(model)
  let life_class = if model.player is None {
    " town-life-unsettled town-onboarding town-onboarding-stage-0"
  } else if onboarding {
    " town-onboarding town-onboarding-stage-\{stage}"
  } else {
    " town-graduated"
  }
  let children : Array[@rabbita.Html] = [
    render_golden_valley_canvas(dispatch, snapshot, town_canvas_view),
    if energy_valley_intersection_reference_requested() {
      render_intersection_reference_legend()
    } else {
      @html.nothing
    },
    if reference_osm_block_graph_ready() ||
      (!intersection_preview && authoritative_energy_valley_transport_ready()) {
      div(class="energy-valley-osm-attribution", [
        a(
          href="https://www.openstreetmap.org/copyright",
          attrs=@html.Attrs::build().aria_label(
            "OpenStreetMap contributors and copyright",
          ),
          "© OpenStreetMap contributors",
        ),
      ])
    } else {
      @html.nothing
    },
    if intersection_preview {
      @html.nothing
    } else {
      render_map_lab_canvas(snapshot, map_lab_canvas_view)
    },
    div(
      class="town-topbar pointer-events-none absolute inset-x-0 top-3 flex justify-center px-3",
      render_energy_valley_topbar(dispatch, model),
    ),
    if model.energy_intro_open || intersection_preview {
      @html.nothing
    } else {
      render_policy_hall_map_entry(dispatch, model)
    },
    match model.selection {
      Agent(_) => @html.nothing
      _ if onboarding => @html.nothing
      _ =>
        div(
          class="town-status-wrap pointer-events-none absolute bottom-4 left-4",
          render_energy_valley_status_panel(dispatch, model, snapshot),
        )
    },
    div(
      class="town-inspector-wrap pointer-events-none absolute right-4 top-24",
      attrs=@html.Attrs::build().aria_live("polite"),
      render_energy_valley_inspector(dispatch, model, snapshot),
    ),
    div(
      class="town-tool-wrap pointer-events-none absolute bottom-4 left-1/2 -translate-x-1/2",
      render_energy_valley_tool_dock(dispatch, model),
    ),
    match model.selection {
      Agent(_) =>
        div(
          class="town-agent-detail-wrap pointer-events-auto absolute bottom-4 left-4 max-w-[320px]",
          render_energy_valley_agent_detail_card(dispatch, model),
        )
      _ => @html.nothing
    },
    if onboarding {
      @html.nothing
    } else {
      div(
        class="town-metric-wrap pointer-events-none absolute right-4 top-24 flex flex-col items-end gap-2",
        [render_energy_valley_dashboard(dispatch, model)],
      )
    },
    if model.energy_intro_open {
      div(
        class="town-modal-backdrop pointer-events-auto bg-slate-950/70",
        attrs=@html.Attrs::build()
          .role("dialog")
          .aria_modal("true")
          .aria_labelledby("avatar-wizard-title"),
        [
          render_avatar_wizard(dispatch, model),
          button(
            class="avatar-wizard-skip",
            on_click=dispatch(CloseEnergyIntro),
            if model.player is Some(_) {
              "取消编辑"
            } else {
              "先随便逛逛，稍后再创建角色"
            },
          ),
          render_phone_fab(dispatch, model),
        ],
      )
    } else {
      @html.nothing
    },
    if model.energy_guide_open {
      div(
        class="town-modal-backdrop pointer-events-auto bg-slate-950/60",
        render_energy_valley_guide(dispatch),
      )
    } else {
      @html.nothing
    },
    if model.energy_reset_open {
      div(
        class="town-modal-backdrop pointer-events-auto bg-slate-950/60",
        render_energy_valley_reset_dialog(dispatch),
      )
    } else {
      @html.nothing
    },
    if model.energy_request_open {
      div(
        class="town-modal-backdrop pointer-events-auto bg-slate-950/60",
        render_energy_valley_request_dialog(dispatch, model),
      )
    } else {
      @html.nothing
    },
    div(class="town-quest-wrap pointer-events-none", [
      render_quest_tracker(dispatch, model),
      if model.player is None && !model.energy_intro_open {
        div(class="quest-tracker pointer-events-auto", [
          div(class="quest-tracker-head", [
            span(class="quest-tracker-badge", "入住"),
            span(class="quest-tracker-title", "创建你的角色"),
          ]),
          div(class="quest-tracker-hint", [
            span(
              "有了自己的角色，才能走路、聊天、盖楼、收藏。",
            ),
            button(
              class="square-action mt-1",
              on_click=dispatch(AvatarOpenEditor),
              "立即创建",
            ),
          ]),
        ])
      } else {
        @html.nothing
      },
    ]),
    div(class="town-player-wrap pointer-events-none", [
      render_player_chip(dispatch, model),
    ]),
    if intersection_preview {
      @html.nothing
    } else {
      render_player_walk_buttons(dispatch, model)
    },
    if intersection_preview {
      @html.nothing
    } else {
      render_metro_legend(dispatch, model)
    },
    if model.energy_intro_open {
      @html.nothing
    } else {
      render_phone_fab(dispatch, model)
    },
    render_phone_panel(dispatch, model),
    render_square_panel(dispatch, model),
    render_resident_explorer(dispatch, model),
    render_town_chronicle(dispatch, model),
    render_town_action_rail(dispatch, model, onboarding, stage),
    render_energy_valley_handoff_layer(dispatch, model),
    render_knowledge_dialog(dispatch, model),
    render_ops_center(dispatch, model),
    render_energy_valley_toast_stack(dispatch, model),
    if onboarding || intersection_preview {
      @html.nothing
    } else {
      render_map_lab(dispatch, map_lab_view, snapshot)
    },
  ]
  for overlay in render_energy_valley_overlays(dispatch, model) {
    children.push(overlay)
  }
  div(
    class="energy-valley-golden relative h-screen w-screen overflow-hidden bg-slate-950 select-none" +
      life_class,
    children,
  )
}

///|
fn render_energy_valley_toast_stack(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if model.energy_toast.is_empty() && model.life_toast.is_empty() {
    return @html.nothing
  }
  div(class="town-toast-stack pointer-events-none", [
    if model.energy_toast.is_empty() {
      @html.nothing
    } else {
      div(
        class="town-toast",
        attrs=@html.Attrs::build().aria_live("polite"),
        model.energy_toast,
      )
    },
    if model.life_toast.is_empty() {
      @html.nothing
    } else {
      div(
        class="life-toast pointer-events-auto",
        attrs=@html.Attrs::build().aria_live("polite"),
        [
          span(model.life_toast),
          button(
            class="life-toast-close",
            on_click=dispatch(CloseLifeToast),
            attrs=@html.Attrs::build().aria_label("关闭提示"),
            "✕",
          ),
        ],
      )
    },
  ])
}

///|
/// MoonTown town-services menu: onboarding exposes only the visible entrance
/// for the current task. Once graduated, secondary surfaces share one native
/// disclosure instead of competing with the map as permanent edge buttons.
fn render_town_action_rail(
  dispatch : Dispatch[Msg],
  model : Model,
  onboarding : Bool,
  stage : Int,
) -> @rabbita.Html {
  let actions : Array[@rabbita.Html] = []
  if !onboarding {
    actions.push(
      button(
        class=if model.phone_open {
          "town-action town-action-primary town-action-active"
        } else {
          "town-action town-action-primary"
        },
        title="联系居民与 MoonClaw",
        on_click=dispatch(TogglePhone),
        attrs=@html.Attrs::build()
          .aria_label("打开谷光联络台")
          .aria_controls("town-phone-panel")
          .aria_expanded(if model.phone_open { "true" } else { "false" }),
        "联络",
      ),
    )
    actions.push(
      button(
        class=if model.resident_explorer_open {
          "town-action town-action-secondary town-action-active"
        } else {
          "town-action town-action-secondary"
        },
        title="寻找真实运行时居民与工作证据",
        on_click=dispatch(ToggleResidentExplorer),
        attrs=@html.Attrs::build()
          .aria_label("居民名册")
          .aria_controls("resident-explorer-panel")
          .aria_expanded(
            if model.resident_explorer_open {
              "true"
            } else {
              "false"
            },
          ),
        "居民",
      ),
    )
    actions.push(
      button(
        class=if model.town_chronicle_open {
          "town-action town-action-secondary town-action-active"
        } else {
          "town-action town-action-secondary"
        },
        title="查看由真实任务账本生成的小镇今日",
        on_click=dispatch(ToggleTownChronicle),
        attrs=@html.Attrs::build()
          .aria_label("小镇今日")
          .aria_controls("town-chronicle-panel")
          .aria_expanded(
            if model.town_chronicle_open {
              "true"
            } else {
              "false"
            },
          ),
        "今日",
      ),
    )
    actions.push(
      button(
        class=if model.metro_visible {
          "town-action town-action-secondary town-action-active"
        } else {
          "town-action town-action-secondary"
        },
        title="显示 / 隐藏地铁 17 号线",
        on_click=dispatch(ToggleMetro),
        attrs=@html.Attrs::build()
          .aria_label("地铁 17 号线图层")
          .aria_pressed(if model.metro_visible { "true" } else { "false" }),
        "17号线",
      ),
    )
    actions.push(
      button(
        class=if model.energy_status_open {
          "town-action town-action-secondary town-action-active"
        } else {
          "town-action town-action-secondary"
        },
        title="查看真实运行时任务与证据",
        on_click=dispatch(ToggleEnergyStatus),
        attrs=@html.Attrs::build()
          .aria_label("运行状态与证据")
          .aria_controls("town-runtime-status")
          .aria_expanded(
            if model.energy_status_open {
              "true"
            } else {
              "false"
            },
          ),
        "运行状态",
      ),
    )
  }
  if !onboarding || stage == 5 || stage == 6 {
    actions.push(
      button(
        class=if model.square_open {
          "town-action town-action-primary town-action-active"
        } else {
          "town-action town-action-primary"
        },
        title="发布与收藏知识大楼",
        on_click=dispatch(ToggleSquare),
        attrs=@html.Attrs::build().aria_label("小镇知识广场"),
        "知识广场",
      ),
    )
  }
  if !onboarding {
    actions.push(
      button(
        class=if model.ops_open {
          "town-action town-action-secondary town-action-active"
        } else {
          "town-action town-action-secondary"
        },
        title="镇长运营看板",
        on_click=dispatch(ToggleOps),
        attrs=@html.Attrs::build().aria_label("能源谷运营中心"),
        "运营",
      ),
    )
    actions.push(
      button(
        class=if model.map_lab_open {
          "town-action town-action-secondary town-action-active"
        } else {
          "town-action town-action-secondary"
        },
        title="高级地图诊断 · Shift+M",
        on_click=dispatch(ToggleMapLab),
        attrs=@html.Attrs::build()
          .aria_label("打开地图诊断")
          .aria_controls("map-lab-panel")
          .aria_expanded(if model.map_lab_open { "true" } else { "false" }),
        "地图诊断",
      ),
    )
  }
  actions.push(
    button(
      class="town-action town-action-secondary",
      on_click=dispatch(OpenEnergyGuide),
      attrs=@html.Attrs::build().aria_label("打开能源谷指南"),
      "指南",
    ),
  )
  if !onboarding {
    actions.push(
      button(
        class="town-action town-action-secondary",
        title="重置小镇",
        on_click=dispatch(OpenEnergyReset),
        attrs=@html.Attrs::build().aria_label("重置小镇"),
        "重置",
      ),
    )
  }
  if onboarding {
    div(class="town-actions town-actions-onboarding", actions)
  } else {
    @html.details(
      class="town-actions town-utility-disclosure pointer-events-auto",
      attrs=@html.Attrs::build().name("moontown-hud-disclosure"),
      [
        @html.summary(class="town-action town-action-menu-toggle", "镇务"),
        div(class="town-utility-panel", actions),
      ],
    )
  }
}

///|
fn render_energy_valley_handoff_layer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="energy-valley-handoff-layer", [
    render_research_handoff_panel(dispatch, model),
    render_moonflow_receiver_panel(dispatch, model),
  ])
}
