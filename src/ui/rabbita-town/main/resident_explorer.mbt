///|
/// Resolve the runtime work item that most directly belongs to an Agent.
/// Work-item identity is authoritative; agent/run references are conservative
/// fallbacks for older but still valid runtime projections.
fn resident_runtime_task_for_agent_in_projection(
  projection : EnergyValleyRuntimeProjection,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  energy_valley_runtime_task_for_agent_in_projection(projection, agent)
}

///|
fn resident_runtime_task_for_agent(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  energy_valley_runtime_task_for_agent(model.energy_valley_runtime, agent)
}

///|
fn resident_runtime_agent_by_id(
  model : Model,
  agent_id : String,
) -> EnergyValleyRuntimeAgent? {
  match model.energy_valley_runtime.projection {
    None => None
    Some(projection) => {
      let identity = strip_prefix_once(agent_id, "runtime:")
      for agent in projection.agents {
        if agent.id == identity {
          return Some(agent)
        }
      }
      None
    }
  }
}

///|
fn resident_status_copy(
  phase : EnergyValleyRuntimePhase,
  status : String,
) -> (String, String) {
  let status_label = match status {
    "running" => "执行中"
    "assigned" => "已分派"
    "waiting" | "queued" => "等待中"
    "waiting_review" => "等待审阅"
    "reviewing" => "审阅中"
    "blocked" => "受阻"
    "failed" => "失败"
    "completed" => "已完成"
    "offline" => "离线"
    "idle" => "待命"
    other => other
  }
  match phase {
    Live => {
      let tone = match status {
        "running" | "assigned" | "reviewing" => "is-active"
        "waiting" | "queued" | "waiting_review" => "is-waiting"
        "blocked" | "failed" => "is-alert"
        "completed" => "is-complete"
        _ => "is-idle"
      }
      (status_label, tone)
    }
    Stale => ("最近记录 · \{status_label}", "is-stale")
    Loading => ("正在连接运行时", "is-loading")
    Unavailable => ("运行时不可用", "is-unavailable")
    Error => ("运行时读取失败", "is-error")
  }
}

///|
fn resident_phase_copy(state : EnergyValleyRuntimeState) -> (String, String) {
  match state.phase {
    Live =>
      (
        "实时居民", "当前名单来自最新的 MoonTown 运行时投影。",
      )
    Stale =>
      (
        "最近居民", "快照已过期；保留身份与工作收据，但不声称他们仍在工作。",
      )
    Loading =>
      ("连接中", "正在等待第一份可核验的运行时居民投影。")
    Unavailable =>
      (
        "运行时不可用", "没有可展示的真实居民；本地剧本联系人不会混进这个名单。",
      )
    Error =>
      (
        "读取失败", "运行时投影未通过读取或校验；这里不会用动画居民补位。",
      )
  }
}

///|
fn resident_role_label(role : String) -> String {
  match role {
    "mayor" => "Mayor · 镇务编排"
    "keeper" => "Keeper · 知识守护"
    "worker" => "Worker · 执行 Agent"
    other => other
  }
}

///|
fn resident_avatar_mark(agent : EnergyValleyRuntimeAgent) -> String {
  match agent.avatarRef {
    Some("avatar://otter-steward") => "K"
    Some("avatar://moon-lantern") => "M"
    _ => worker_avatar_initials(agent.name)
  }
}

///|
fn render_runtime_resident_avatar(
  agent : EnergyValleyRuntimeAgent,
  extra_class : String,
) -> @rabbita.Html {
  let style = [
    "--worker-image: url('\{energy_valley_runtime_agent_sprite_asset(agent, 0)}')",
  ]
  div(
    class="resident-avatar resident-avatar-sprite worker-sprite-roster \{extra_class}",
    style~,
    attrs=@html.Attrs::build()
      .role("img")
      .aria_label("\{agent.name} 的角色形象"),
    [
      span(class="worker-sprite", no_children()),
      span(
        class="resident-avatar-fallback",
        attrs=@html.Attrs::build().aria_hidden("true"),
        resident_avatar_mark(agent),
      ),
    ],
  )
}

///|
fn resident_task_runtime_building_identity(
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  energy_valley_runtime_task_civic_id(task)
}

///|
fn resident_workplace_identity(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
) -> String {
  match golden_valley_optional_nonempty(agent.destinationBuildingModuleKey) {
    Some(identity) if identity != "energy-lab" => return identity
    None => ()
    _ => ()
  }
  match task {
    Some(work) =>
      match golden_valley_optional_nonempty(work.destinationBuildingModuleKey) {
        Some(identity) if identity != "energy-lab" => return identity
        None => ()
        _ => ()
      }
    None => ()
  }
  match golden_valley_optional_nonempty(agent.buildingModuleKey) {
    Some(identity) if identity != "energy-lab" => return identity
    _ => ()
  }
  match task {
    Some(work) => return resident_task_runtime_building_identity(work)
    None => ()
  }
  agent.buildingModuleKey.unwrap_or("")
}

///|
fn resident_origin_identity(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
) -> String {
  match golden_valley_optional_nonempty(agent.originBuildingModuleKey) {
    Some(identity) => identity
    None =>
      match task {
        Some(work) => work.originBuildingModuleKey.unwrap_or("")
        None => ""
      }
  }
}

///|
fn resident_building_label(model : Model, identity : String) -> String {
  if identity.is_empty() {
    return "未记录"
  }
  let buildings = golden_valley_buildings(active_energy_valley_seed())
  for custom in energy_valley_model_buildings(model) {
    buildings.push(custom)
  }
  match golden_valley_building_for_identity(buildings, identity) {
    Some(building) => building.name
    None =>
      match find_wenyu_module(identity) {
        Some(civic) => civic.title
        None => identity
      }
  }
}

///|
fn resident_activity_copy(
  phase : EnergyValleyRuntimePhase,
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
) -> String {
  let unsafe_recorded = match
    golden_valley_optional_nonempty(agent.activityLabel) {
    Some(label) => label
    None =>
      match task {
        Some(work) =>
          match golden_valley_optional_nonempty(work.activityLabel) {
            Some(label) => label
            None => work.summary.unwrap_or(work.title)
          }
        None => "没有关联的真实工作项"
      }
  }
  let recorded = energy_valley_safe_runtime_copy(
    unsafe_recorded, "活动描述包含本地路径或过长内容，已隐藏；请从允许的结果页核验。",
    240,
  )
  match phase {
    Live => recorded
    Stale => "最近记录：\{recorded}"
    Loading => "正在连接运行时；暂不推测当前活动"
    Unavailable => "运行时不可用；暂不推测当前活动"
    Error => "运行时读取失败；暂不推测当前活动"
  }
}

///|
fn resident_collaboration_count(task : EnergyValleyRuntimeWorkItem?) -> Int {
  match task {
    Some(work) =>
      match work.collaboration {
        Some(collaboration) => collaboration.participants.length()
        None => 0
      }
    None => 0
  }
}

///|
fn resident_evidence_count(task : EnergyValleyRuntimeWorkItem?) -> Int {
  match task {
    None => 0
    Some(work) =>
      work.resultLinks
      .unwrap_or([])
      .filter(energy_valley_runtime_result_link_is_valid)
      .length()
  }
}

///|
fn resident_safe_task_summary(summary : String) -> String {
  energy_valley_safe_runtime_copy(
    summary, "任务摘要包含本地路径或过长内容，已在居民资料中隐藏；请从允许的结果页核验产物。",
    1200,
  )
}

///|
fn resident_search_blob(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
  workplace_label : String,
) -> String {
  let work = match task {
    None => ""
    Some(item) =>
      "\{item.id} \{item.title} \{item.status} \{item.buildingModuleKey} \{item.bookId.unwrap_or("")} \{item.runId.unwrap_or("")} \{item.summary.unwrap_or("")} \{item.source}"
  }
  "\{agent.id} \{agent.name} \{agent.role} \{agent.status} \{agent.runId.unwrap_or("")} \{agent.bookId.unwrap_or("")} \{agent.activityLabel.unwrap_or("")} \{workplace_label} \{work}".to_lower()
}

///|
fn resident_matches_query(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
  workplace_label : String,
  query : String,
) -> Bool {
  let needle = query.trim().to_owned().to_lower()
  needle.is_empty() ||
  resident_search_blob(agent, task, workplace_label).contains(needle)
}

///|
fn resident_runtime_agents_matching(
  model : Model,
  query : String,
) -> Array[EnergyValleyRuntimeAgent] {
  match model.energy_valley_runtime.projection {
    None => []
    Some(projection) =>
      projection.agents.filter(agent => {
        let task = resident_runtime_task_for_agent_in_projection(
          projection, agent,
        )
        let workplace = resident_workplace_identity(agent, task)
        resident_matches_query(
          agent,
          task,
          resident_building_label(model, workplace),
          query,
        )
      })
  }
}

///|
fn render_resident_runtime_badge(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> @rabbita.Html {
  let (label, tone) = resident_status_copy(
    model.energy_valley_runtime.phase,
    agent.status,
  )
  span(class="resident-status \{tone}", [
    span(class="resident-status-dot", ""),
    span(label),
  ])
}

///|
fn render_resident_roster_row(
  dispatch : Dispatch[Msg],
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> @rabbita.Html {
  let task = resident_runtime_task_for_agent(model, agent)
  let workplace_identity = resident_workplace_identity(agent, task)
  let selected = match model.selection {
    Agent(agent_id) => strip_prefix_once(agent_id, "runtime:") == agent.id
    _ => false
  }
  button(
    class=if selected {
      "resident-roster-row is-selected"
    } else {
      "resident-roster-row"
    },
    on_click=dispatch(SelectAgent(agent.id)),
    attrs=@html.Attrs::build()
      .aria_label("查看居民 \{agent.name} 的真实工作资料")
      .aria_controls("resident-profile-panel")
      .aria_expanded(if selected { "true" } else { "false" })
      .aria_pressed(if selected { "true" } else { "false" }),
    [
      render_runtime_resident_avatar(agent, "resident-roster-avatar"),
      span(class="resident-roster-copy", [
        span(class="resident-roster-name", agent.name),
        span(class="resident-roster-role", resident_role_label(agent.role)),
        span(
          class="resident-roster-place",
          resident_building_label(model, workplace_identity),
        ),
      ]),
      span(class="resident-roster-state", [
        render_resident_runtime_badge(model, agent),
        span(class="resident-roster-arrow", "→"),
      ]),
    ],
  )
}

///|
fn render_resident_explorer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if !model.resident_explorer_open {
    return @html.nothing
  }
  let residents = resident_runtime_agents_matching(model, model.resident_query)
  let total = match model.energy_valley_runtime.projection {
    Some(projection) => projection.agents.length()
    None => 0
  }
  let (phase_label, phase_detail) = resident_phase_copy(
    model.energy_valley_runtime,
  )
  section(
    id="resident-explorer-panel",
    class="resident-explorer pointer-events-auto",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("false")
      .aria_labelledby("resident-explorer-title"),
    [
      header(class="resident-explorer-head", [
        div(class="resident-explorer-heading", [
          p(class="resident-explorer-eyebrow", "RUNTIME RESIDENTS"),
          h2(id="resident-explorer-title", "镇上居民"),
          p(
            "找人、看他正在负责的真实工作，再进入建筑或发起协作。",
          ),
        ]),
        button(
          class="resident-explorer-close",
          on_click=dispatch(ToggleResidentExplorer),
          attrs=@html.Attrs::build().aria_label("关闭居民列表"),
          "✕",
        ),
      ]),
      div(class="resident-explorer-phase", [
        span(class="resident-explorer-phase-label", phase_label),
        span(phase_detail),
      ]),
      div(class="resident-search", [
        @html.label(for_="resident-search-input", "搜索真实居民"),
        input(
          id="resident-search-input",
          class="resident-search-input",
          autofocus=true,
          placeholder="名字、角色、建筑、任务、Run ID…",
          value=model.resident_query,
          on_input=value => dispatch(ResidentSearch(value)),
          attrs=@html.Attrs::build().aria_label(
            "按名字、角色、建筑、任务或 Run ID 搜索真实居民",
          ),
        ),
        span(class="resident-search-count", "\{residents.length()}/\{total}"),
      ]),
      div(class="resident-roster", [
        if residents.is_empty() {
          div(class="resident-roster-empty", [
            @html.strong(
              if total == 0 {
                "没有可核验的 Runtime Agent"
              } else {
                "没有匹配的居民"
              },
            ),
            span(
              if total == 0 {
                energy_valley_runtime_phase_detail(model.energy_valley_runtime)
              } else {
                "换一个名字、建筑、任务标题或 Run ID 试试。"
              },
            ),
          ])
        } else {
          div(
            class="resident-roster-list",
            residents.map(agent => {
              render_resident_roster_row(dispatch, model, agent)
            }),
          )
        },
      ]),
      @html.footer(class="resident-explorer-foot", [
        span("身份源：MoonTown runtime projection"),
        span("本地剧本联系人不会混入真实居民名单"),
      ]),
    ],
  )
}

///|
fn render_resident_fact(label : String, value : String) -> @rabbita.Html {
  div(class="resident-fact", [@html.dt(label), @html.dd(value)])
}

///|
fn render_resident_evidence(
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  let links = task.resultLinks
    .unwrap_or([])
    .filter(energy_valley_runtime_result_link_is_valid)
  div(class="resident-evidence", [
    div(class="resident-section-head", [
      h3("结果与证据"),
      span("\{links.length()} 个可打开结果"),
    ]),
    if links.is_empty() {
      p(
        class="resident-empty-copy",
        "运行时尚未记录可打开的结果页。",
      )
    } else {
      div(
        class="resident-evidence-links",
        links.map(link => {
          a(
            href=link.url,
            class="resident-evidence-link",
            attrs=@html.Attrs::build().aria_label(
              "打开 \{link.label} 结果证据",
            ),
            [
              span(class="resident-evidence-kind", link.kind),
              @html.strong(link.label),
              span(class="resident-evidence-arrow", "↗"),
            ],
          )
        }),
      )
    },
    if task.artifacts.is_empty() {
      @html.nothing
    } else {
      p(
        class="resident-artifact-count",
        "\{task.artifacts.length()} 个运行时 artifact 已记录；为避免暴露本地绝对路径，此处只显示数量。",
      )
    },
  ])
}

///|
fn render_resident_collaboration(
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  match task.collaboration {
    None =>
      p(
        class="resident-empty-copy",
        "这项工作没有记录协作参与者。",
      )
    Some(collaboration) =>
      if collaboration.participants.is_empty() {
        p(
          class="resident-empty-copy",
          "这项工作没有记录协作参与者。",
        )
      } else {
        div(class="resident-collaboration", [
          p("协作模式 · \{collaboration.mode}"),
          div(
            class="resident-collaborator-list",
            collaboration.participants.map(participant => {
              div(class="resident-collaborator", [
                span(class="resident-collaborator-family", participant.family),
                span("\{participant.status} · \{participant.runId}"),
              ])
            }),
          ),
        ])
      }
  }
}

///|
fn render_resident_work_receipt(
  model : Model,
  task : EnergyValleyRuntimeWorkItem,
) -> @rabbita.Html {
  let (status_label, status_tone) = resident_status_copy(
    model.energy_valley_runtime.phase,
    task.status,
  )
  let receipt_label = if model.energy_valley_runtime.phase is Live {
    "工作收据"
  } else {
    "最近工作收据"
  }
  div(class="resident-work", [
    div(class="resident-section-head", [
      div([
        p(class="resident-section-kicker", receipt_label),
        h3(
          energy_valley_safe_runtime_copy(
            task.title,
            "任务标题包含本地路径或过长内容，已隐藏。",
            240,
          ),
        ),
      ]),
      span(class="resident-task-state \{status_tone}", status_label),
    ]),
    @html.details(class="resident-receipt-details", [
      @html.summary(
        "查看任务收据 · \{resident_evidence_count(Some(task))} 个结果",
      ),
      match task.summary {
        Some(summary) if !summary.trim().is_empty() =>
          div(class="resident-task-summary-disclosure", [
            h3("运行时任务摘要"),
            p(resident_safe_task_summary(summary)),
          ])
        _ => @html.nothing
      },
      @html.dl(class="resident-facts", [
        render_resident_fact("Work item", task.id),
        render_resident_fact("Run ID", task.runId.unwrap_or("未记录")),
        render_resident_fact("Book", task.bookId.unwrap_or("未记录")),
        render_resident_fact("Source", task.source),
        render_resident_fact("Updated", task.updatedAt.unwrap_or("未记录")),
        render_resident_fact(
          "Collaboration",
          "\{resident_collaboration_count(Some(task))} participants",
        ),
      ]),
      render_resident_collaboration(task),
      render_resident_evidence(task),
    ]),
  ])
}

///|
fn render_resident_profile_for_agent(
  dispatch : Dispatch[Msg],
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> @rabbita.Html {
  let task = resident_runtime_task_for_agent(model, agent)
  let workplace_identity = resident_workplace_identity(agent, task)
  let workplace_label = resident_building_label(model, workplace_identity)
  let origin_identity = resident_origin_identity(agent, task)
  let activity = resident_activity_copy(
    model.energy_valley_runtime.phase,
    agent,
    task,
  )
  section(
    id="resident-profile-panel",
    class="resident-profile",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("false")
      .aria_labelledby("resident-profile-title"),
    [
      header(class="resident-profile-head", [
        render_runtime_resident_avatar(agent, "resident-profile-avatar"),
        div(class="resident-profile-identity", [
          p(class="resident-profile-source", "RUNTIME AGENT · \{agent.id}"),
          h2(id="resident-profile-title", agent.name),
          p(resident_role_label(agent.role)),
        ]),
        button(
          class="resident-profile-close",
          autofocus=true,
          on_click=dispatch(SelectOverview),
          attrs=@html.Attrs::build().aria_label("关闭居民资料"),
          "✕",
        ),
      ]),
      div(class="resident-profile-status", [
        render_resident_runtime_badge(model, agent),
        span(activity),
      ]),
      @html.dl(class="resident-profile-locations", [
        render_resident_fact(
          "归属建筑",
          if workplace_identity.is_empty() {
            "未记录"
          } else {
            "\{workplace_label} · \{workplace_identity}"
          },
        ),
        render_resident_fact(
          "路线起点",
          if origin_identity.is_empty() {
            "未记录"
          } else {
            "\{resident_building_label(model, origin_identity)} · \{origin_identity}"
          },
        ),
      ]),
      div(class="resident-profile-actions", [
        if workplace_identity.is_empty() {
          button(
            class="resident-action is-disabled",
            attrs=@html.Attrs::build()
              .disabled(true)
              .aria_label("该居民没有已记录的归属建筑"),
            "没有归属建筑",
          )
        } else {
          button(
            class="resident-action",
            on_click=dispatch(OpenEnergyBuilding(workplace_identity)),
            "定位工作建筑",
          )
        },
        button(
          class="resident-action is-primary",
          on_click=dispatch(
            OpenEnergyRequestForAgent(phone_runtime_contact_id(agent)),
          ),
          "用此上下文创建工作请求",
        ),
      ]),
      div(class="resident-truth-note", [
        @html.strong(
          if model.energy_valley_runtime.phase is Live {
            "实时投影"
          } else {
            "历史快照"
          },
        ),
        span(
          "身份、任务、Run ID 和结果链接来自 \{model.energy_valley_runtime.projection.map(projection => projection.schema).unwrap_or("MoonTown runtime")}；界面不会把行走动画当作完成证据。",
        ),
      ]),
      match task {
        Some(work) => render_resident_work_receipt(model, work)
        None =>
          div(class="resident-work resident-work-empty", [
            h3("没有关联的真实工作项"),
            p(
              "这个身份来自运行时投影，但当前没有 Work item、Run ID 或结果页可供核验。",
            ),
          ])
      },
    ],
  )
}

///|
/// Truthful replacement for the former hard-coded Agent card. It deliberately
/// fails closed when a selected identity is absent from the current snapshot.
fn render_selected_resident_profile(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let agent_id = match model.selection {
    Agent(id) => id
    _ => return @html.nothing
  }
  match resident_runtime_agent_by_id(model, agent_id) {
    Some(agent) => render_resident_profile_for_agent(dispatch, model, agent)
    None =>
      section(
        id="resident-profile-panel",
        class="resident-profile resident-profile-missing",
        attrs=@html.Attrs::build()
          .role("dialog")
          .aria_modal("false")
          .aria_labelledby("resident-profile-title"),
        [
          header(class="resident-profile-head", [
            span(class="resident-avatar resident-profile-avatar", "?"),
            div(class="resident-profile-identity", [
              p(class="resident-profile-source", "RUNTIME IDENTITY"),
              h2(id="resident-profile-title", agent_id),
              p("当前投影中不存在"),
            ]),
            button(
              class="resident-profile-close",
              on_click=dispatch(SelectOverview),
              attrs=@html.Attrs::build().aria_label("关闭居民资料"),
              "✕",
            ),
          ]),
          p(
            class="resident-empty-copy",
            "这个 Agent 可能已经结束、重启或更换身份。MoonTown 不会用演示居民补写它的任务和结果。",
          ),
        ],
      )
  }
}
