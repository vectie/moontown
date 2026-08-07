///|
fn energy_valley_weather_icon(weather : EnergyWeather) -> String {
  match weather {
    Sunny => "☀️"
    Cloudy => "☁️"
    Rain => "🌧️"
    Snow => "❄️"
  }
}

///|
fn energy_valley_weather_label(weather : EnergyWeather) -> String {
  match weather {
    Sunny => "晴天"
    Cloudy => "多云"
    Rain => "雨天"
    Snow => "雪天"
  }
}

///|
fn energy_valley_tool_active(model : Model, tool : EnergyTool) -> String {
  if model.energy_tool == tool {
    " bg-amber-300/25 ring-1 ring-amber-300/60"
  } else {
    " hover:bg-white/10"
  }
}

///|
fn render_energy_valley_weather_button(
  dispatch : Dispatch[Msg],
  model : Model,
  weather : EnergyWeather,
) -> @rabbita.Html {
  let selected = model.energy_weather == weather
  let selected_class = if selected {
    " bg-amber-300/25 ring-1 ring-amber-300/50"
  } else {
    " hover:bg-white/10 opacity-60"
  }
  button(
    class="rounded-lg px-1.5 py-1 text-sm transition" + selected_class,
    title=if model.energy_weather_auto {
      "手动指定后自动天气关闭"
    } else {
      energy_valley_weather_label(weather)
    },
    on_click=dispatch(SetEnergyWeather(weather)),
    attrs=@html.Attrs::build()
      .aria_label("天气：\{energy_valley_weather_label(weather)}")
      .aria_pressed(if selected { "true" } else { "false" }),
    energy_valley_weather_icon(weather),
  )
}

///|
fn energy_valley_sim_minutes(model : Model) -> Int {
  552 + model.tick * model.energy_time_scale / 60
}

///|
fn energy_valley_two_digits(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    value.to_string()
  }
}

///|
fn energy_valley_sim_clock(model : Model) -> String {
  let minutes = energy_valley_sim_minutes(model) % (24 * 60)
  "\{energy_valley_two_digits(minutes / 60)}:\{energy_valley_two_digits(minutes % 60)}"
}

///|
fn energy_valley_sim_day(model : Model) -> Int {
  1 + energy_valley_sim_minutes(model) / (24 * 60)
}

///|
fn render_energy_valley_topbar(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let auto_class = if model.energy_weather_auto {
    " town-topbar-auto-on"
  } else {
    ""
  }
  let board_class = if model.energy_board_open {
    " town-topbar-chip-on"
  } else {
    ""
  }
  div(class="town-topbar-inner pointer-events-auto", [
    div(class="town-topbar-identity", [
      img(src="moontown.svg", alt="", class="town-topbar-logo"),
      div(class="town-topbar-name", [
        div(class="town-topbar-title", "MoonTown · 能源谷"),
        div(
          class="town-topbar-sub",
          "WENYU VALLEY · \{active_energy_valley_seed_label()}",
        ),
      ]),
    ]),
    div(class="town-topbar-sep", no_children()),
    div(class="town-topbar-clock", [
      span(class="town-topbar-time", energy_valley_sim_clock(model)),
      span(class="town-topbar-day", "第 \{energy_valley_sim_day(model)} 天"),
    ]),
    div(class="town-topbar-sep town-topbar-sep-wide", no_children()),
    div(class="town-topbar-weather", [
      render_energy_valley_weather_button(dispatch, model, Sunny),
      render_energy_valley_weather_button(dispatch, model, Cloudy),
      render_energy_valley_weather_button(dispatch, model, Rain),
      render_energy_valley_weather_button(dispatch, model, Snow),
      button(
        class="town-topbar-auto" + auto_class,
        on_click=dispatch(ToggleEnergyWeatherAuto),
        attrs=@html.Attrs::build()
          .aria_label("自动天气")
          .aria_pressed(
            if model.energy_weather_auto {
              "true"
            } else {
              "false"
            },
          ),
        "自动",
      ),
    ]),
    div(class="town-topbar-sep town-topbar-sep-wide", no_children()),
    div(class="town-topbar-sim", [
      button(
        class="town-topbar-pause",
        title="空格键",
        on_click=dispatch(TogglePause),
        attrs=@html.Attrs::build()
          .aria_label(
            if model.paused {
              "继续模拟"
            } else {
              "暂停模拟"
            },
          )
          .aria_pressed(if model.paused { "true" } else { "false" }),
        if model.paused {
          "▶️"
        } else {
          "⏸️"
        },
      ),
      render_energy_valley_speed_button(dispatch, model, 30, "1×"),
      render_energy_valley_speed_button(dispatch, model, 60, "2×"),
      render_energy_valley_speed_button(dispatch, model, 240, "8×"),
    ]),
    div(class="town-topbar-sep town-topbar-sep-wide", no_children()),
    div(class="town-topbar-metrics", [
      render_energy_valley_metric(
        "👥",
        energy_valley_known_resident_count(model).to_string(),
      ),
      render_energy_valley_metric("⚡", model.energy.to_string()),
      render_energy_valley_metric(
        "💰",
        energy_valley_model_budget(model).to_string(),
      ),
      render_energy_valley_metric(
        "🤖",
        energy_valley_environment_agent_count(model).to_string(),
      ),
    ]),
    div(class="town-topbar-sep town-topbar-sep-wide", no_children()),
    div(class="town-topbar-actions", [
      button(
        class="town-topbar-chip" + board_class,
        on_click=dispatch(ToggleEnergyBoard),
        attrs=@html.Attrs::build().aria_expanded(
          if model.energy_board_open {
            "true"
          } else {
            "false"
          },
        ),
        "📊 看板",
      ),
      button(
        class="town-topbar-chip",
        on_click=dispatch(OpenEnergyGuide),
        "指南",
      ),
      button(
        class="town-topbar-chip",
        title="重置小镇",
        on_click=dispatch(OpenEnergyReset),
        "重置",
      ),
    ]),
  ])
}

///|
fn render_energy_valley_status_panel(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  let claims_live_work = energy_valley_runtime_can_claim_active_work(
    model.energy_valley_runtime,
  )
  let recorded_work_count = energy_valley_runtime_work_count(model)
  let (label, detail, tone) = energy_valley_runtime_phase_copy(
    model.energy_valley_runtime,
  )
  let open_class = if model.energy_status_open {
    " town-status-open"
  } else {
    ""
  }
  div(class="town-status" + open_class, [
    button(
      class="town-status-summary",
      on_click=dispatch(ToggleEnergyStatus),
      attrs=@html.Attrs::build()
        .aria_label(
          if model.energy_status_open {
            "收起运行状态"
          } else {
            "展开运行状态"
          },
        )
        .aria_expanded(if model.energy_status_open { "true" } else { "false" }),
      [
        span(class="town-status-dot \{tone}", ""),
        span(class="town-status-text", [
          span(class="town-status-label", label),
          span(class="town-status-detail", detail),
        ]),
        span(
          class="town-status-count",
          if claims_live_work {
            "\{recorded_work_count} 项"
          } else if recorded_work_count > 0 {
            "快照 · \{recorded_work_count}"
          } else {
            "0 项"
          },
        ),
        span(
          class="town-status-chevron",
          if model.energy_status_open {
            "▾"
          } else {
            "▸"
          },
        ),
      ],
    ),
    if model.energy_status_open {
      div(class="town-status-body", [
        render_ecosystem_attention_digest(dispatch, model, snapshot),
        render_knowledge_flow_preview_legend(model),
        render_energy_valley_event_feed(model),
        p(
          class="town-status-note",
          if !claims_live_work && recorded_work_count > 0 {
            "以下仅为最近一次有效快照，不表示 Agent 当前仍在运行。"
          } else if recorded_work_count == 0 {
            "连接真实运行时后，任务、Agent、建筑和产物会在这里出现。"
          } else {
            "展开真实任务可查看 Agent、Run ID、协作参与者与产物。"
          },
        ),
        button(
          class="town-status-cta",
          on_click=dispatch(OpenEnergyRequest),
          "Create real work",
        ),
      ])
    } else {
      @html.nothing
    },
  ])
}

///|
fn render_energy_valley_metric(icon : String, value : String) -> @rabbita.Html {
  div(class="flex items-center gap-1.5", [
    span(class="text-sm", icon),
    span(class="font-mono font-semibold text-slate-100", value),
  ])
}

///|
fn render_energy_valley_speed_button(
  dispatch : Dispatch[Msg],
  model : Model,
  scale : Int,
  label : String,
) -> @rabbita.Html {
  let selected = model.energy_time_scale == scale
  let selected_class = if selected {
    " bg-amber-300/25 text-amber-100 ring-1 ring-amber-300/50"
  } else {
    " text-slate-400 hover:bg-white/10"
  }
  button(
    class="rounded-lg px-1.5 py-1 text-[11px] font-mono" + selected_class,
    on_click=dispatch(SetEnergyTimeScale(scale)),
    attrs=@html.Attrs::build()
      .aria_label("模拟速度 \{label}")
      .aria_pressed(if selected { "true" } else { "false" }),
    label,
  )
}

///|
fn energy_valley_environment_agent_count(model : Model) -> Int {
  energy_valley_runtime_active_agents(model.energy_valley_runtime).length()
}

///|
/// Truthful resident count: the embodied player plus agents actually present
/// in the latest runtime projection. Decorative preview walkers are excluded.
fn energy_valley_known_resident_count(model : Model) -> Int {
  let player_count = if model.player is Some(_) { 1 } else { 0 }
  match model.energy_valley_runtime.projection {
    Some(projection) => player_count + projection.agents.length()
    None => player_count
  }
}

///|
fn render_energy_valley_dock_button(
  dispatch : Dispatch[Msg],
  model : Model,
  tool : EnergyTool,
  icon : String,
  label : String,
  cost : String,
  hotkey : String,
  building? : Bool = false,
) -> @rabbita.Html {
  button(
    class="group town-dock-button relative flex flex-col items-center gap-0.5 rounded-xl px-2.5 py-1.5 transition" +
      energy_valley_tool_active(model, tool),
    title=if cost.is_empty() { label } else { "\{label} · 花费 \{cost}" },
    on_click=dispatch(SetEnergyTool(tool)),
    attrs=@html.Attrs::build()
      .aria_label(
        if cost.is_empty() {
          "\{label}，快捷键 \{hotkey}"
        } else {
          "\{label}，花费 \{cost}，快捷键 \{hotkey}"
        },
      )
      .aria_pressed(if model.energy_tool == tool { "true" } else { "false" }),
    [
      span(
        class=if building {
          "flex h-7 w-7 items-center justify-center rounded-md bg-gradient-to-br from-indigo-400/80 to-sky-500/80 text-[13px] font-bold text-white shadow"
        } else {
          "text-lg"
        },
        icon,
      ),
      span(class="text-[10px] text-slate-300", label),
      if cost.is_empty() {
        @html.nothing
      } else {
        span(class="town-dock-cost", cost)
      },
      span(
        class="absolute -top-1.5 -right-1 rounded bg-white/10 px-1 text-[8px] text-slate-400 opacity-0 transition group-hover:opacity-100",
        hotkey,
      ),
    ],
  )
}

///|
fn render_energy_valley_tool_dock(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let progress = quest_progress_count(model)
  let onboarding = current_quest(model) is Some(_)
  // During onboarding expose only the control required by the current step.
  // The full construction palette returns after graduation.
  if onboarding && progress != 2 && progress != 4 {
    return @html.nothing
  }
  let tools : Array[@rabbita.Html] = []
  if !onboarding || progress == 2 {
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        InspectTool,
        "🖐️",
        "视察",
        "",
        "1",
      ),
    )
  }
  if !onboarding {
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        RoadTool,
        "🛣️",
        "铺路",
        "30 · 桥120",
        "2",
      ),
    )
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        ParkTool,
        "🌳",
        "造林",
        "20",
        "3",
      ),
    )
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        DemolishTool,
        "🧹",
        "拆除",
        "",
        "4",
      ),
    )
  }
  if !onboarding {
    tools.push(div(class="mx-1 h-10 w-px bg-white/10", no_children()))
  }
  if !onboarding || progress == 4 {
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        ResearchTowerTool,
        "研",
        "研发塔楼",
        "800",
        "5",
        building=true,
      ),
    )
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        LaboratoryTool,
        "实",
        "实验室",
        "500",
        "6",
        building=true,
      ),
    )
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        WorkshopTool,
        "坊",
        "创新工坊",
        "400",
        "7",
        building=true,
      ),
    )
  }
  if !onboarding {
    tools.push(
      render_energy_valley_dock_button(
        dispatch,
        model,
        TalentHomeTool,
        "寓",
        "人才公寓",
        "350",
        "8",
        building=true,
      ),
    )
  }
  div(
    class="town-tool-dock pointer-events-auto flex items-end gap-2 rounded-2xl bg-slate-950/60 px-3 py-2 backdrop-blur-md border border-white/10 shadow-xl",
    tools,
  )
}

///|
fn energy_valley_runtime_work_count(model : Model) -> Int {
  match model.energy_valley_runtime.projection {
    Some(projection) => projection.tasks.length()
    None => 0
  }
}

///|
fn energy_valley_runtime_phase_copy(
  state : EnergyValleyRuntimeState,
) -> (String, String, String) {
  match state.phase {
    Live =>
      (
        "真实运行",
        match state.projection {
          Some(projection) =>
            match projection.tick {
              Some(tick) => "运行时 tick \{tick}"
              None => "已连接 MoonTown"
            }
          None => "已连接 MoonTown"
        },
        "bg-emerald-400",
      )
    Loading =>
      (
        "知识流预览", "正在连接 · 画面为示意，并非真实工作",
        "bg-sky-400",
      )
    Stale =>
      (
        "知识流预览", "运行时数据过期 · 已保留最近一次有效证据",
        "bg-amber-400",
      )
    Error =>
      ("知识流预览", "连接出错 · 移动仅为示意", "bg-rose-400")
    Unavailable =>
      (
        "知识流预览", "未连接运行时 · 当前为确定性演示，而非真实执行",
        "bg-slate-400",
      )
  }
}

///|
fn render_knowledge_flow_preview_legend(model : Model) -> @rabbita.Html {
  if !energy_valley_knowledge_preview_visible(model) {
    return @html.nothing
  }
  div(class="knowledge-flow-preview-legend", [
    span(class="knowledge-flow-preview-title", "地图来源"),
    div(class="knowledge-flow-preview-states", [
      span(class="is-real", "● REAL · 运行时证据"),
      span(class="is-preview", "◇ PREVIEW · 环境日程"),
    ]),
    p(
      "实心标记只表示当前实时工作；虚线菱形是 12 位环境居民，不计入 Agent、任务与完成统计。",
    ),
  ])
}

///|
fn render_energy_valley_event_feed(model : Model) -> @rabbita.Html {
  let has_live_work = energy_valley_runtime_can_claim_active_work(
    model.energy_valley_runtime,
  )
  let events : Array[@rabbita.Html] = []
  if energy_valley_knowledge_preview_visible(model) {
    events.push(
      div(
        class="knowledge-flow-preview-event flex items-center gap-2 rounded-xl bg-slate-950/70 px-3 py-1.5 backdrop-blur-sm border border-violet-300/20 text-[11px] text-violet-100",
        [
          span("◇"),
          span(class="font-semibold", "知识流预览"),
          span(
            class="text-violet-200/70",
            if has_live_work {
              "环境居民与真实 Agent 并行；紫色虚线气泡为预览"
            } else {
              "示意画面 · 0 个实时任务"
            },
          ),
        ],
      ),
    )
  }
  if !has_live_work {
    let (weather_icon, weather_copy) = match model.energy_weather {
      Sunny => ("☀️", "天气晴朗")
      Cloudy => ("☁️", "云层聚拢")
      Rain => ("🌧️", "温榆河起雨了")
      Snow => ("❄️", "飘雪覆盖能源谷")
    }
    events.push(
      div(
        class="flex items-center gap-2 rounded-xl bg-slate-950/50 px-3 py-1.5 backdrop-blur-sm border border-white/5 text-[12px] text-slate-200",
        [span(weather_icon), span(weather_copy)],
      ),
    )
    events.push(
      div(
        class="flex items-center gap-2 rounded-xl bg-slate-950/50 px-3 py-1.5 backdrop-blur-sm border border-white/5 text-[12px] text-slate-200",
        style=["opacity: .78"],
        [span("🌄"), span("第 \{energy_valley_sim_day(model)} 天开始")],
      ),
    )
  }
  div(class="pointer-events-none flex w-72 flex-col gap-1", events)
}

///|
fn golden_valley_building_description(
  building : GoldenValleyBuilding,
) -> String {
  match golden_valley_building_module_key(building) {
    "town-shell" => "Town Shell · 全镇协议中枢"
    "policy-hall" => "Policy Hall · 协议制定与治理"
    "vitality-tower" => "Vitality Tower · 活力信号守望"
    "contest-express" => "Contest Express · 众创任务集散"
    "story-radar" => "Story Radar · 叙事锻造"
    "resident-twins" => "Resident Twins · 数字分身之家"
    "ai-garden" => "AI Garden · 学习共同体"
    "social-square" => "Social Square · 协作与公共交流"
    "research-embodied-robotics" => "Robotics Lab · 具身智能研究"
    "research-ai-agents" => "AI Agents Lab · 多智能体研究"
    "talent-avenue" => "Talent Avenue · 人才撮合市集"
    "valley-market" => "Valley Market · 资源撮合"
    "physical-bridge" => "Physical Bridge · 实体连接实验"
    "research-opc" => "OPC Research · 一人公司研究"
    "research-llm-training" => "LLM Training Lab · 模型训练研究"
    "research-ai-hardware" => "AI Hardware Lab · 智能硬件研究"
    _ =>
      match building.style {
        "custom-tower" => "研发塔楼 · 自定义研究空间"
        "custom-lab" => "实验室 · 自定义实验空间"
        "custom-home" => "人才公寓 · 自定义居住空间"
        _ => "创新工坊 · 自定义生产空间"
      }
  }
}

///|
fn golden_valley_building_kind_label(building : GoldenValleyBuilding) -> String {
  match golden_valley_building_module_key(building) {
    id if id.has_prefix("research-") => "研究模块"
    "resident-twins" | "talent-avenue" => "社区模块"
    "ai-garden" | "social-square" => "公共模块"
    "valley-market" => "交换模块"
    "physical-bridge" => "基础设施模块"
    "" => "自定义建筑"
    _ => "市政协议模块"
  }
}

///|
fn render_energy_valley_inspector(
  dispatch : Dispatch[Msg],
  model : Model,
  town_snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  match model.energy_selected_building {
    Some(building) =>
      match find_knowledge_domain_for_building(model, building) {
        Some(domain) =>
          return render_knowledge_domain_inspector_shell(
            dispatch, model, building, domain, town_snapshot,
          )
        None => ()
      }
    None => ()
  }
  match model.energy_selected_building {
    None => @html.nothing
    Some(building) => {
      let building_tasks = golden_valley_runtime_tasks_for_building(
        model.energy_valley_runtime,
        building,
      )
      let semantic_interior = match
        town_snapshot_place_for_building_view(model, town_snapshot, building) {
        Some(place) => render_town_snapshot_place_interior(town_snapshot, place)
        None => @html.nothing
      }
      let claims_live_work = energy_valley_runtime_can_claim_active_work(
        model.energy_valley_runtime,
      )
      let interior_link = @html.nothing
      div(
        class="town-generic-inspector pointer-events-auto w-64 rounded-2xl bg-slate-950/70 p-4 backdrop-blur-md border border-white/10 shadow-2xl",
        [
          div(class="mb-1 flex items-start justify-between", [
            div([
              div(class="text-[15px] font-bold text-amber-100", building.name),
              div(
                class="text-[11px] text-slate-400",
                golden_valley_building_description(building),
              ),
            ]),
            button(
              class="min-h-11 min-w-11 rounded-lg text-slate-400 hover:bg-white/10",
              on_click=dispatch(CloseEnergyInspector),
              attrs=@html.Attrs::build().aria_label("关闭建筑详情"),
              "✕",
            ),
          ]),
          div(
            class="mb-2 rounded-lg bg-indigo-400/15 px-2 py-1 text-[10px] text-indigo-200 ring-1 ring-indigo-300/30",
            "\{golden_valley_building_kind_label(building)} · \{building.style}",
          ),
          render_ecosystem_place_story(model, building, town_snapshot),
          div(class="mt-3 border-t border-white/10 pt-2", [
            div(
              class="mb-1 flex items-center justify-between text-[10px] tracking-wider text-slate-400",
              [
                span(
                  if claims_live_work {
                    "真实工作"
                  } else {
                    "最近真实快照"
                  },
                ),
                span(building_tasks.length().to_string()),
              ],
            ),
            if building_tasks.is_empty() {
              p(
                class="text-[10px] leading-relaxed text-slate-500",
                if claims_live_work {
                  "这座建筑当前没有真实运行时任务。"
                } else {
                  "当前显示最后一次真实快照；连接状态并非实时。"
                },
              )
            } else {
              let task_cards : Array[@rabbita.Html] = []
              if !claims_live_work {
                task_cards.push(
                  p(
                    class="rounded-lg border border-amber-300/15 bg-amber-300/[0.05] px-2 py-1.5 text-[10px] leading-relaxed text-amber-100/70",
                    "保留记录仅供追溯，不表示这些 Agent 当前仍在执行。",
                  ),
                )
              }
              let task_count = if building_tasks.length() < 3 {
                building_tasks.length()
              } else {
                3
              }
              for index in 0..<task_count {
                let task = building_tasks[index]
                let run_id = task.runId.unwrap_or("no run")
                task_cards.push(
                  div(
                    class="rounded-lg bg-white/[0.04] px-2 py-1.5 text-[10px]",
                    [
                      div(class="truncate text-slate-200", task.title),
                      div(
                        class="mt-0.5 truncate font-mono text-slate-500",
                        "\{task.status} · \{run_id}",
                      ),
                    ],
                  ),
                )
              }
              div(class="flex flex-col gap-1", task_cards)
            },
          ]),
          semantic_interior,
          interior_link,
        ],
      )
    }
  }
}

///|
fn render_energy_valley_dashboard_work_list(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  match model.energy_valley_runtime.projection {
    None =>
      div(
        class="flex min-h-28 items-center justify-center rounded-xl bg-white/[0.03] px-6 text-center text-[11px] leading-relaxed text-slate-400",
        "运行时未连接。地图仍可浏览，但环境 Agent 不会被计作真实工作。",
      )
    Some(projection) => {
      if projection.tasks.is_empty() {
        return div(
          class="flex min-h-28 items-center justify-center rounded-xl bg-white/[0.03] px-6 text-center text-[11px] leading-relaxed text-slate-400",
          if energy_valley_runtime_can_claim_active_work(
              model.energy_valley_runtime,
            ) {
            "运行时已连接，但当前快照没有记录任务。"
          } else {
            "最近有效快照没有记录任务；当前连接并非实时。"
          },
        )
      }
      let cards : Array[@rabbita.Html] = []
      let shown = if projection.tasks.length() < 5 {
        projection.tasks.length()
      } else {
        5
      }
      for index in 0..<shown {
        let task = projection.tasks[index]
        let civic_id = energy_valley_runtime_task_civic_id(task)
        let agents = energy_valley_runtime_agents_for_task(
          model.energy_valley_runtime,
          task.id,
        )
        cards.push(
          button(
            class="block w-full rounded-lg border border-white/10 bg-white/[0.04] px-2.5 py-2 text-left hover:border-amber-200/30 hover:bg-white/[0.08] focus:outline-none focus:ring-2 focus:ring-amber-200/50",
            on_click=dispatch(OpenEnergyBuilding(civic_id)),
            attrs=@html.Attrs::build().aria_label(
              "Open \{task.title} building library on the town canvas",
            ),
            [
              div(class="flex items-start justify-between gap-3", [
                span(
                  class="truncate text-[11px] font-semibold text-slate-100",
                  task.title,
                ),
                span(
                  class="shrink-0 rounded-full bg-white/10 px-1.5 py-0.5 font-mono text-[9px] text-slate-300",
                  task.status,
                ),
              ]),
              div(
                class="mt-1 flex items-center justify-between gap-3 font-mono text-[9px] text-slate-500",
                [
                  span(class="truncate", task.buildingModuleKey),
                  span(
                    "\{agents.length()} agent · \{task.runId.unwrap_or("no run")}",
                  ),
                ],
              ),
            ],
          ),
        )
      }
      div(class="flex flex-col gap-1.5 rounded-xl bg-white/[0.03] p-2", [
        div(class="flex flex-col gap-1.5", cards),
        if projection.tasks.length() > shown {
          p(
            class="px-1 text-[9px] text-slate-500",
            "另有 \{projection.tasks.length() - shown} 项记录；进入对应建筑查看 Agent、协作参与者与产物。",
          )
        } else {
          p(
            class="px-1 text-[9px] text-slate-500",
            "进入对应建筑查看 Agent、协作参与者与产物。",
          )
        },
      ])
    }
  }
}

///|
fn render_energy_valley_dashboard(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if !model.energy_board_open {
    return @html.nothing
  }
  div(
    class="town-dashboard pointer-events-auto flex w-[38rem] flex-col gap-3 rounded-2xl bg-slate-950/75 p-4 backdrop-blur-md border border-white/10 shadow-2xl",
    [
      div(class="flex items-center justify-between", [
        div(
          class="text-[15px] font-bold text-amber-100",
          "📊 能源谷运行看板",
        ),
        div(class="flex items-center gap-1", [
          button(
            class="rounded-lg px-2 py-0.5 text-[11px] text-slate-400 hover:bg-white/10 hover:text-slate-200",
            on_click=dispatch(OpenEnergyGuide),
            "指南",
          ),
          button(
            class="min-h-11 min-w-11 rounded-lg text-slate-400 hover:bg-white/10",
            on_click=dispatch(ToggleEnergyBoard),
            attrs=@html.Attrs::build().aria_label("关闭能源谷运行看板"),
            "✕",
          ),
        ]),
      ]),
      div(class="town-dashboard-chart rounded-xl bg-white/5 p-3", [
        div(class="mb-1 flex justify-between text-[11px] text-slate-400", [
          span("全镇活力 · 48 小时"),
          span(class="font-mono text-emerald-300", model.energy.to_string()),
        ]),
        div(
          class="flex h-11 items-center justify-center text-[10px] text-slate-500",
          "数据积累中…",
        ),
      ]),
      div(class="flex rounded-xl bg-white/5 p-1", [
        span(
          class="flex-1 rounded-lg py-1.5 text-[11px] bg-amber-300/20 text-amber-100",
          if energy_valley_runtime_can_claim_active_work(
              model.energy_valley_runtime,
            ) {
            "真实工作 · \{energy_valley_runtime_work_count(model)}"
          } else {
            "快照记录 · \{energy_valley_runtime_work_count(model)}"
          },
        ),
        span(
          class="flex-1 rounded-lg py-1.5 text-center text-[11px] text-slate-400",
          "市政服务 · \{wenyu_module_count()}",
        ),
        span(
          class="flex-1 rounded-lg py-1.5 text-center text-[11px] text-slate-400",
          "运行活动 · 4",
        ),
      ]),
      render_energy_valley_dashboard_work_list(dispatch, model),
      div(
        class="flex items-center justify-between border-t border-white/10 pt-2 text-[10px] text-slate-500",
        [
          span(
            if energy_valley_runtime_can_claim_active_work(
                model.energy_valley_runtime,
              ) {
              "工作数据来自 MoonTown 运行时 · 环境指标为本地模拟"
            } else {
              "保留最后一次真实快照 · 不推测新的工作状态"
            },
          ),
          button(
            class="rounded-lg px-2 py-1 text-slate-400 hover:bg-white/10 hover:text-rose-200",
            on_click=dispatch(OpenEnergyReset),
            "重置小镇",
          ),
        ],
      ),
    ],
  )
}

///|
/// Render the first-agent selection card shown when energy_first_agent_open is true
/// and no agent has been selected yet. Lets the player pick their first agent.
fn render_energy_valley_first_agent(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let agents = [
    ("resident_01", "小陈", "🔬 研究员 · 喜欢在书楼编码"),
    ("resident_05", "小李", "🏗️ 建造师 · 擅长修路盖楼"),
    ("resident_12", "小王", "🌿 环境师 · 专注绿化和生态"),
    ("resident_24", "小张", "📊 分析师 · 数据与金融建模"),
  ]
  div(
    class="town-modal-backdrop pointer-events-auto bg-slate-950/70",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("true")
      .aria_labelledby("first-agent-title"),
    [
      div(
        class="w-[380px] rounded-2xl border border-amber-200/20 bg-slate-950/95 p-5 shadow-2xl",
        [
          h2(
            id="first-agent-title",
            class="mb-1 text-[17px] font-bold text-amber-100",
            "选择你的第一位居民",
          ),
          p(
            class="mb-4 text-[12px] text-slate-400",
            "每位居民有不同特长。你可以随时招募更多。",
          ),
          div(
            class="flex flex-col gap-2",
            agents.map(fn(agent) {
              let (id, name, desc) = agent
              button(
                class="flex items-start gap-3 rounded-xl border border-white/10 bg-white/5 p-3 text-left hover:border-amber-300/40 hover:bg-white/10",
                on_click=dispatch(SelectAgent(id)),
                [
                  div(class="mt-0.5 text-[20px]", "🧑"),
                  div(class="flex-1", [
                    div(class="text-[14px] font-semibold text-amber-100", name),
                    div(class="text-[11px] text-slate-400", desc),
                  ]),
                  div(class="text-slate-500", "→"),
                ],
              )
            }),
          ),
          div(class="mt-4 flex justify-end gap-2", [
            button(
              class="rounded-lg px-3 py-1.5 text-[12px] text-slate-400 hover:bg-white/5",
              on_click=dispatch(CloseEnergyIntro),
              "稍后再说",
            ),
          ]),
        ],
      ),
    ],
  )
}

///|
fn render_energy_valley_onboarding(dispatch : Dispatch[Msg]) -> @rabbita.Html {
  div(
    class="pointer-events-auto w-[340px] rounded-2xl bg-slate-950/85 p-5 backdrop-blur-md border border-amber-200/20 shadow-2xl",
    [
      div(
        class="mb-2 text-[16px] font-bold text-amber-100",
        "欢迎来到能源谷 🌙",
      ),
      div(
        class="flex flex-col gap-2 text-[12.5px] leading-relaxed text-slate-300",
        [
          p(
            "这里是按昌平未来科学城 · 能源谷空间规则生成的 AI 小镇。连接 MoonTown 运行时后，真实任务会派遣 Agent 前往对应建筑；未连接时会明确标为环境模拟。",
          ),
          p(
            "🖐️ 视察：点击建筑或小人查看详情，可跟随 Agent 视角\n🛣️ 搭建：底部工具坞可铺路、造林、建造新楼宇\n🌦️ 环境：左上角切换天气，右上角调节时间流速",
          ),
        ],
      ),
      button(
        class="mt-3 w-full rounded-xl bg-amber-300/90 py-2 text-[13px] font-bold text-slate-900 hover:bg-amber-200",
        on_click=dispatch(CloseEnergyIntro),
        "进入小镇",
      ),
      button(
        class="mt-2 w-full rounded-xl py-1.5 text-[12px] text-slate-400 hover:bg-white/5 hover:text-slate-200",
        on_click=dispatch(OpenEnergyGuide),
        "先看完整操作指南",
      ),
    ],
  )
}

///|
/// Render a detail card for the currently selected agent (model.selection = Agent(id)).
/// Shows name, role, current activity, and a "dismiss" button.
fn render_energy_valley_agent_detail_card(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  render_selected_resident_profile(dispatch, model)
}

///|
fn render_energy_valley_guide_card(
  title : String,
  copy : String,
) -> @rabbita.Html {
  div(class="rounded-xl bg-white/5 p-3", [
    div(class="mb-1 font-semibold text-amber-100", title),
    div(copy),
  ])
}

///|
fn render_energy_valley_guide(dispatch : Dispatch[Msg]) -> @rabbita.Html {
  section(
    class="pointer-events-auto w-full max-w-3xl rounded-2xl border border-amber-200/20 bg-slate-950/95 p-5 shadow-2xl backdrop-blur-md",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("true")
      .aria_labelledby("town-guide-title"),
    [
      div(class="flex items-start justify-between gap-4", [
        div([
          h2(
            id="town-guide-title",
            class="text-[17px] font-bold text-amber-100",
            "能源谷操作指南",
          ),
          p(
            class="mt-1 text-[12px] text-slate-400",
            "真实工作来自 MoonTown 运行时；地图建设和环境状态保存在本机。",
          ),
        ]),
        button(
          class="rounded-lg px-2 py-1 text-slate-400 hover:bg-white/10",
          on_click=dispatch(CloseEnergyGuide),
          attrs=@html.Attrs::build().aria_label("关闭指南"),
          "✕",
        ),
      ]),
      div(
        class="mt-4 grid gap-3 text-[12px] leading-relaxed text-slate-300 sm:grid-cols-2",
        [
          render_energy_valley_guide_card(
            "1 · 你的角色", "第一次进入会创建属于你的角色。点左下角「🚶 行走」后点击地图即可走过去，也可以直接用 WASD / 方向键移动，「🎥 跟随」让相机跟着你。",
          ),
          render_energy_valley_guide_card(
            "2 · 虚拟手机", "右下角 📱 打开谷光手机：离线居民会用明确标注的本地剧本即时回复，也可能主动提醒；真实 Runtime Agent 只展示可核验工作动态，暂不伪装成可聊天。",
          ),
          render_energy_valley_guide_card(
            "3 · 逛大楼", "用视察工具点击任意大楼，能看到里面的真实任务、Agent 与 Run ID；拖动平移、滚轮缩放。沿温榆河走走，还能找到地铁 17 号线的两座车站。",
          ),
          render_energy_valley_guide_card(
            "4 · 产出知识大楼", "底部工具坞选研发塔楼/实验室/创新工坊，找空地放下，落成后给它注入知识主题——这栋楼就是你的知识作品。",
          ),
          render_energy_valley_guide_card(
            "5 · 分享与收藏", "打开「🏛️ 广场」：把自己的知识楼在本机标记为可分享，并生成普通网页链接；也可以把已完成、可核验的共建成果收藏进自己的小镇。",
          ),
          render_energy_valley_guide_card(
            "6 · 任务与运营", "左上角任务链带你上手全部玩法，完成得谷光值解锁称号；每天可签到。「🏙️ 运营」展示本机活动计数、当前资料的任务旅程与运行时快照，不把单浏览器数据冒充多用户活跃或留存。",
          ),
        ],
      ),
      div(
        class="mt-3 rounded-xl bg-white/5 p-3 text-[11px] text-slate-400",
        "快捷键：1–8 切换工具 · 空格暂停/继续 · Esc 返回视察并关闭面板",
      ),
      button(
        class="mt-4 w-full rounded-xl bg-amber-300/90 py-2 text-[13px] font-bold text-slate-900 hover:bg-amber-200",
        on_click=dispatch(CloseEnergyGuide),
        "开始探索",
      ),
    ],
  )
}

///|
fn render_energy_valley_reset_dialog(dispatch : Dispatch[Msg]) -> @rabbita.Html {
  section(
    class="pointer-events-auto w-full max-w-sm rounded-2xl border border-rose-300/20 bg-slate-950/95 p-5 shadow-2xl backdrop-blur-md",
    attrs=@html.Attrs::build()
      .role("alertdialog")
      .aria_modal("true")
      .aria_labelledby("reset-town-title"),
    [
      h2(
        id="reset-town-title",
        class="text-[16px] font-bold text-amber-100",
        "重置或生成能源谷",
      ),
      p(
        class="mt-2 text-[12px] leading-relaxed text-slate-300",
        "「重置本谷」保留当前地形种子，只清除你的建设；「生成新谷」会按同一套能源谷规则创建新的河流、湿地、路网、城区与建筑布局。",
      ),
      div(class="mt-4 grid grid-cols-2 gap-2", [
        button(
          class="flex-1 rounded-xl bg-white/10 py-2 text-[12px] text-slate-200 hover:bg-white/15",
          autofocus=true,
          on_click=dispatch(CloseEnergyReset),
          "取消",
        ),
        button(
          class="flex-1 rounded-xl bg-white/10 py-2 text-[12px] text-slate-100 hover:bg-white/15",
          on_click=dispatch(EnergyResetCurrent),
          "重置本谷",
        ),
        button(
          class="col-span-2 rounded-xl bg-emerald-500/80 py-2 text-[12px] font-semibold text-white hover:bg-emerald-400",
          on_click=dispatch(EnergyGenerateNew),
          "⟳ 生成新谷",
        ),
      ]),
    ],
  )
}

///|
fn render_energy_valley_request_dialog(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  section(
    class="energy-request-dialog pointer-events-auto max-h-[90vh] w-full max-w-4xl overflow-auto rounded-2xl border border-amber-200/20 bg-slate-950/95 p-5 text-slate-100 shadow-2xl backdrop-blur-md",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("true")
      .aria_labelledby("energy-request-title"),
    [
      div(class="mb-4 flex items-start justify-between gap-4", [
        div([
          h2(
            id="energy-request-title",
            class="text-[17px] font-bold text-amber-100",
            "创建真实工作请求",
          ),
          p(
            class="mt-1 text-[12px] text-slate-400",
            "提交后由 MoonTown 运行时保存持续观察请求，并由 Mayor 调度执行 Agent；进度和结果会通过运行时账本回投到能源谷。",
          ),
        ]),
        button(
          class="energy-request-dialog-close rounded-lg px-2 py-1 text-slate-400 hover:bg-white/10",
          autofocus=true,
          on_click=dispatch(CloseEnergyRequest),
          attrs=@html.Attrs::build().aria_label("关闭真实工作请求"),
          "✕",
        ),
      ]),
      render_request_desk(dispatch, model),
    ],
  )
}

///|
fn render_energy_valley_agent_activity_popup(
  _dispatch : Dispatch[Msg],
  agent : GoldenValleyCanvasAgent,
) -> @rabbita.Html {
  div(
    class="agent-activity-popup pointer-events-auto absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-44 rounded-xl border border-amber-200/15 bg-slate-950/90 p-2.5 shadow-xl backdrop-blur-sm",
    attrs=@html.Attrs::build().aria_hidden("true"),
    [
      div(class="flex items-center gap-1.5 text-[11px] text-amber-200/80", [
        span(agent.activity_glyph),
        span(agent.activity_label),
      ]),
      div(class="mt-1 h-1 w-full overflow-hidden rounded-full bg-white/10", [
        div(
          class="h-full w-2/3 rounded-full bg-gradient-to-r from-amber-400/60 to-emerald-400/60",
          ([] : Array[@rabbita.Html]),
        ),
      ]),
      div(
        class="mt-1 flex items-center justify-between text-[9px] text-slate-500",
        [
          div(class="flex items-center gap-1", [
            div(
              class="h-1.5 w-1.5 rounded-full bg-emerald-400/80",
              ([] : Array[@rabbita.Html]),
            ),
            span("工作 · \{agent.work_color}"),
          ]),
          span(if agent.preview { "预览" } else { "活动中" }),
        ],
      ),
    ],
  )
}

///|
fn render_energy_valley_first_agent_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let agents = match model.energy_valley_runtime.projection {
    Some(proj) => proj.agents
    None => []
  }
  if agents.is_empty() {
    return @html.nothing
  }
  let agent = agents[0]
  let activity = agent.activityLabel.unwrap_or("在能源谷中待命")
  div(
    class="pointer-events-auto w-56 rounded-2xl border border-amber-200/20 bg-slate-950/90 p-3 shadow-2xl backdrop-blur-sm",
    attrs=@html.Attrs::build()
      .role("region")
      .aria_labelledby("first-agent-title"),
    [
      div(class="flex items-center gap-2", [
        span(class="text-[20px]", "\u{1F9D1}"),
        div([
          h3(
            id="first-agent-title",
            class="text-[13px] font-semibold text-amber-100",
            agent.name,
          ),
          p(class="text-[10px] text-slate-400", "\{agent.role} · \{activity}"),
        ]),
      ]),
      div(class="mt-2 flex items-center gap-1.5 text-[11px] text-slate-300", [
        div(class="h-2 w-2 rounded-full inline-block bg-emerald-400", ""),
        span("状态 "),
        span(class="font-mono text-amber-300", agent.status),
      ]),
      div(class="mt-2 flex gap-1.5", [
        button(
          class="flex-1 rounded-lg bg-white/10 py-1.5 text-[11px] text-slate-200 hover:bg-white/20",
          on_click=dispatch(SelectAgent(agent.id)),
          "查看居民",
        ),
        button(
          class="flex-1 rounded-lg bg-emerald-500/60 py-1.5 text-[11px] text-white hover:bg-emerald-400/70",
          on_click=dispatch(OpenEnergyGuide),
          "查看指南",
        ),
      ]),
      if agents.length() > 1 {
        p(
          class="mt-2 text-[10px] text-slate-500",
          "还有 \{agents.length() - 1} 位居民在能源谷中",
        )
      } else {
        @html.nothing
      },
    ],
  )
}

///|
/// Canvas-local overlays. The onboarding / guide / reset / request dialogs are
/// owned by the standalone page (which wraps them in accessible role="dialog"
/// containers), so the golden viewport intentionally does not re-mount them —
/// doing so rendered each dialog twice. Only the first-agent welcome panel,
/// which is unique to this surface, is composed here.
fn render_energy_valley_overlays(
  dispatch : Dispatch[Msg],
  model : Model,
) -> Array[@rabbita.Html] {
  let overlays : Array[@rabbita.Html] = []
  // First-agent welcome overlay shown after intro closes
  if model.energy_first_agent_open {
    overlays.push(
      div(
        class="absolute bottom-20 left-4 z-50",
        render_energy_valley_first_agent_panel(dispatch, model),
      ),
    )
  }
  overlays
}
