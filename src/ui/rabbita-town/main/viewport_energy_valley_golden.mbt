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
fn render_energy_valley_town_badge(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let auto_class = if model.energy_weather_auto {
    " bg-emerald-400/20 text-emerald-200 ring-1 ring-emerald-300/40"
  } else {
    " bg-white/5 text-slate-400"
  }
  div(
    class="pointer-events-auto flex items-center gap-3 rounded-2xl bg-slate-950/60 px-4 py-2.5 backdrop-blur-md border border-white/10 shadow-xl",
    [
      img(src="moontown.svg", alt="", class="h-9 w-9 rounded-xl shadow-lg"),
      div([
        div(
          class="text-[15px] font-bold tracking-wide text-amber-100",
          "MoonTown · 能源谷",
        ),
        div(
          class="text-[10px] text-slate-400 tracking-widest",
          "WENYU VALLEY · \{active_energy_valley_seed_label()}",
        ),
      ]),
      div(class="h-8 w-px bg-white/10", no_children()),
      div(class="text-center", [
        div(
          class="text-[15px] font-mono text-slate-100",
          energy_valley_sim_clock(model),
        ),
        div(
          class="text-[10px] text-slate-400",
          "第 \{energy_valley_sim_day(model)} 天",
        ),
      ]),
      div(class="h-8 w-px bg-white/10", no_children()),
      div(class="flex items-center gap-1", [
        render_energy_valley_weather_button(dispatch, model, Sunny),
        render_energy_valley_weather_button(dispatch, model, Cloudy),
        render_energy_valley_weather_button(dispatch, model, Rain),
        render_energy_valley_weather_button(dispatch, model, Snow),
        button(
          class="ml-1 rounded-lg px-2 py-1 text-[10px] transition" + auto_class,
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
    ],
  )
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
  let real_agents = energy_valley_runtime_active_agents(
    model.energy_valley_runtime,
  ).length()
  if real_agents > 0 {
    real_agents
  } else {
    20
  }
}

///|
fn render_energy_valley_metric_chips(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let board_class = if model.energy_board_open {
    " bg-amber-300/25 text-amber-100 ring-1 ring-amber-300/50"
  } else {
    " text-slate-200 hover:bg-white/10"
  }
  div(class="pointer-events-auto flex items-center gap-2", [
    div(
      class="flex items-center gap-3 rounded-2xl bg-slate-950/60 px-4 py-2.5 backdrop-blur-md border border-white/10 shadow-xl text-[13px]",
      [
        render_energy_valley_metric("👥", "128"),
        render_energy_valley_metric("⚡", model.energy.to_string()),
        render_energy_valley_metric(
          "💰",
          model.energy_build_budget.to_string(),
        ),
        render_energy_valley_metric(
          "🤖",
          energy_valley_environment_agent_count(model).to_string(),
        ),
      ],
    ),
    div(
      class="flex items-center gap-1 rounded-2xl bg-slate-950/60 px-2 py-2 backdrop-blur-md border border-white/10 shadow-xl",
      [
        button(
          class="rounded-lg px-2 py-1 text-sm hover:bg-white/10",
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
        button(
          class="ml-1 rounded-lg px-2.5 py-1 text-[12px]" + board_class,
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
      ],
    ),
  ])
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
    class="group relative flex flex-col items-center gap-0.5 rounded-xl px-2.5 py-1.5 transition" +
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
        span(class="text-[9px] font-mono text-amber-200/80", cost)
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
  div(
    class="pointer-events-auto flex items-end gap-2 rounded-2xl bg-slate-950/60 px-3 py-2 backdrop-blur-md border border-white/10 shadow-xl",
    [
      render_energy_valley_dock_button(
        dispatch,
        model,
        InspectTool,
        "🖐️",
        "视察",
        "",
        "1",
      ),
      render_energy_valley_dock_button(
        dispatch,
        model,
        RoadTool,
        "🛣️",
        "铺路",
        "30 · 桥120",
        "2",
      ),
      render_energy_valley_dock_button(
        dispatch,
        model,
        ParkTool,
        "🌳",
        "造林",
        "20",
        "3",
      ),
      render_energy_valley_dock_button(
        dispatch,
        model,
        DemolishTool,
        "🧹",
        "拆除",
        "",
        "4",
      ),
      div(class="mx-1 h-10 w-px bg-white/10", no_children()),
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
    ],
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
    Loading => ("连接中", "正在读取 MoonTown 运行时", "bg-sky-400")
    Stale =>
      (
        "数据已过期", "保留最后一次真实快照，不推测新工作",
        "bg-amber-400",
      )
    Error =>
      (
        "连接错误", "地图可浏览；Agent 不会冒充执行任务", "bg-rose-400",
      )
    Unavailable =>
      (
        "演示模式", "运行时未连接；移动仅为环境动画", "bg-slate-400",
      )
  }
}

///|
fn render_energy_valley_runtime_summary(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let (label, detail, tone) = energy_valley_runtime_phase_copy(
    model.energy_valley_runtime,
  )
  @html.node(
    "details",
    @html.Attrs::build().class(
      "runtime-work pointer-events-auto w-80 rounded-2xl border border-white/10 bg-slate-950/70 shadow-xl backdrop-blur-md",
    ),
    [
      @html.node(
        "summary",
        @html.Attrs::build().class(
          "flex min-h-11 cursor-pointer list-none items-center gap-2 rounded-2xl px-3 py-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300/70",
        ),
        [
          span(class="h-2.5 w-2.5 rounded-full \{tone}", ""),
          span(class="min-w-0 flex-1", [
            span(class="block text-[11px] font-semibold text-slate-100", label),
            span(class="block truncate text-[10px] text-slate-400", detail),
          ]),
          span(
            class="rounded-lg bg-white/5 px-2 py-1 font-mono text-[10px] text-slate-300",
            "\{energy_valley_runtime_work_count(model)} 项工作",
          ),
        ],
      ),
      div(class="border-t border-white/10 px-3 pb-3 pt-2", [
        p(
          class="rounded-lg bg-white/[0.04] px-2 py-2 text-[10px] leading-relaxed text-slate-400",
          if energy_valley_runtime_work_count(model) == 0 {
            "连接真实运行时后，任务、Agent、建筑和产物会在这里出现。"
          } else {
            "展开真实任务可查看 Agent、Run ID、协作参与者与产物。"
          },
        ),
        button(
          class="mt-2 min-h-11 w-full rounded-lg bg-amber-300 text-[11px] font-bold text-slate-950 hover:bg-amber-200",
          on_click=dispatch(OpenEnergyRequest),
          "Create real work",
        ),
      ]),
    ],
  )
}

///|
fn render_energy_valley_event_feed(model : Model) -> @rabbita.Html {
  let has_real_projection = match model.energy_valley_runtime.projection {
    Some(projection) => projection.mode == "live"
    None => false
  }
  let events : Array[@rabbita.Html] = []
  if !has_real_projection {
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
) -> @rabbita.Html {
  match model.energy_selected_building {
    None => @html.nothing
    Some(building) => {
      let building_tasks = golden_valley_runtime_tasks_for_building(
        model.energy_valley_runtime,
        building,
      )
      let building_agents = golden_valley_runtime_known_agents_for_building(
        model.energy_valley_runtime,
        building,
      )
      let civic_id = golden_valley_building_civic_id(building)
      let interior_link = if civic_id.is_empty() {
        @html.nothing
      } else {
        a(
          href=legacy_viewport_module_href(civic_id),
          class="mt-3 grid min-h-11 place-items-center rounded-xl bg-amber-300 px-3 text-center text-[12px] font-black text-slate-950 no-underline shadow-lg shadow-amber-950/20 hover:bg-amber-200 focus:outline-none focus:ring-2 focus:ring-amber-100",
          "进入建筑 · 查看真实工作",
        )
      }
      div(
        class="pointer-events-auto w-64 rounded-2xl bg-slate-950/70 p-4 backdrop-blur-md border border-white/10 shadow-2xl",
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
          div(class="mt-2", [
            div(
              class="mb-0.5 flex justify-between text-[11px] text-slate-400",
              [span("活力"), span(class="font-mono", "68")],
            ),
            div(class="h-1.5 overflow-hidden rounded-full bg-white/10", [
              div(
                class="h-full rounded-full bg-emerald-400 transition-all",
                style=["width: 68%"],
                no_children(),
              ),
            ]),
          ]),
          div(
            class="mt-2 flex items-center justify-between text-[12px] text-slate-300",
            [
              span(
                if model.energy_valley_runtime.phase is Live {
                  "在内 Agent"
                } else {
                  "快照 Agent"
                },
              ),
              span(
                class="font-mono text-slate-100",
                building_agents.length().to_string(),
              ),
            ],
          ),
          div(class="mt-3 border-t border-white/10 pt-2", [
            div(
              class="mb-1 flex items-center justify-between text-[10px] tracking-wider text-slate-400",
              [span("真实工作"), span(building_tasks.length().to_string())],
            ),
            if building_tasks.is_empty() {
              p(
                class="text-[10px] leading-relaxed text-slate-500",
                if model.energy_valley_runtime.phase is Live {
                  "这座建筑当前没有真实运行时任务。"
                } else {
                  "当前显示最后一次真实快照；连接状态并非实时。"
                },
              )
            } else {
              let task_cards : Array[@rabbita.Html] = []
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
          interior_link,
        ],
      )
    }
  }
}

///|
fn render_energy_valley_dashboard_work_list(model : Model) -> @rabbita.Html {
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
          "运行时已连接，但当前快照没有记录任务。",
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
          a(
            href=legacy_viewport_module_href(civic_id),
            class="block rounded-lg border border-white/10 bg-white/[0.04] px-2.5 py-2 no-underline hover:border-amber-200/30 hover:bg-white/[0.08] focus:outline-none focus:ring-2 focus:ring-amber-200/50",
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
          "真实工作 · \{energy_valley_runtime_work_count(model)}",
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
      render_energy_valley_dashboard_work_list(model),
      div(
        class="flex items-center justify-between border-t border-white/10 pt-2 text-[10px] text-slate-500",
        [
          span(
            if model.energy_valley_runtime.phase is Live {
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
            "1 · 看镇况", "“真实运行”表示任务来自执行快照和台账；“演示模式”中的移动只营造环境，不计作工作。居民、活力与预算仍是地图模拟指标。",
          ),
          render_energy_valley_guide_card(
            "2 · 视察", "点击建筑查看真实任务、Agent 和 Run ID；运行时 Agent 的目的地由任务决定。拖动画面平移，滚轮缩放，角色详情可开启跟随。",
          ),
          render_energy_valley_guide_card(
            "3 · 建设", "底部选择道路、造林或四类建筑，再点地图放置。红色预览表示冲突或预算不足；提示会说明原因。",
          ),
          render_energy_valley_guide_card(
            "4 · 拆除与恢复", "“拆除”可清理自建内容；建筑详情会显示返还比例。“重置本谷”保留地形，“生成新谷”会用新种子重建整张地图。",
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
    class="pointer-events-auto max-h-[90vh] w-full max-w-4xl overflow-auto rounded-2xl border border-amber-200/20 bg-slate-950/95 p-5 text-slate-100 shadow-2xl backdrop-blur-md",
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
            "派遣真实协作工作",
          ),
          p(
            class="mt-1 text-[12px] text-slate-400",
            "提交后由 MoonTown 运行时建立真实请求；Agent、进度和产物会回投到能源谷建筑。",
          ),
        ]),
        button(
          class="rounded-lg px-2 py-1 text-slate-400 hover:bg-white/10",
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
fn render_energy_valley_overlays(
  dispatch : Dispatch[Msg],
  model : Model,
) -> Array[@rabbita.Html] {
  let overlays : Array[@rabbita.Html] = []
  if model.energy_intro_open {
    overlays.push(
      div(
        class="absolute inset-0 z-10 flex items-center justify-center bg-slate-950/40",
        render_energy_valley_onboarding(dispatch),
      ),
    )
  }
  if model.energy_guide_open {
    overlays.push(
      div(
        class="absolute inset-0 z-20 flex items-center justify-center bg-slate-950/55 p-4",
        render_energy_valley_guide(dispatch),
      ),
    )
  }
  if model.energy_reset_open {
    overlays.push(
      div(
        class="absolute inset-0 z-30 flex items-center justify-center bg-slate-950/60 p-4",
        render_energy_valley_reset_dialog(dispatch),
      ),
    )
  }
  if model.energy_request_open {
    overlays.push(
      div(
        class="absolute inset-0 z-40 flex items-center justify-center bg-slate-950/70 p-4",
        render_energy_valley_request_dialog(dispatch, model),
      ),
    )
  }
  overlays
}
