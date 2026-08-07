///|
/// A compact, evidence-bearing story derived from one durable runtime work
/// item. The work item stays attached so its allowlisted result links can be
/// rendered without copying or weakening the runtime contract.
priv struct TownChronicleEntry {
  source_label : String
  state_label : String
  tone : String
  title : String
  detail : String
  observed_at : String
  agent_id : String?
  building_id : String
  evidence_count : Int
  participant_count : Int
  task : EnergyValleyRuntimeWorkItem
}

///|
/// A local-only activity record. These entries are deliberately kept in a
/// separate type and section so browser interactions can never be mistaken
/// for runtime work or multi-user social activity.
priv struct TownChronicleLocalEntry {
  day : String
  label : String
  detail : String
}

///|
/// Terminal handoffs that the runtime explicitly moved out of the live task
/// collection are grouped by book/building. They remain auditable recovery
/// debt without visually competing with work that is actionable now.
priv struct TownChronicleHistoryGroup {
  key : String
  label : String
  building_id : String
  tasks : Array[EnergyValleyRuntimeWorkItem]
}

///|
fn town_chronicle_source_label(source : String) -> String {
  match source {
    "operator-request" => "用户请求"
    "standing-goal" => "长期目标"
    "watcher" => "自动巡查"
    "town-runtime" => "小镇运行时"
    _ => "运行时记录"
  }
}

///|
fn town_chronicle_status_label(status : String) -> String {
  match status {
    "queued" => "排队中"
    "assigned" => "已分派"
    "running" => "执行中"
    "waiting_review" => "等待评审"
    "completed" => "已完成"
    "failed" => "未完成"
    "blocked" => "受阻"
    _ => "已记录"
  }
}

///|
fn town_chronicle_task_tone(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  if !(state.phase is Live) {
    return "history"
  }
  match task.status {
    "completed" => "complete"
    "blocked" | "failed" => "attention"
    "running" | "assigned" => "active"
    "waiting_review" => "review"
    _ => "neutral"
  }
}

///|
fn town_chronicle_projected_agent_for_task(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> EnergyValleyRuntimeAgent? {
  match state.projection {
    None => None
    Some(projection) => {
      match task.agentId {
        Some(agent_id) if !agent_id.trim().is_empty() =>
          for agent in projection.agents {
            if agent.id == agent_id {
              return Some(agent)
            }
          }
        _ => ()
      }
      for agent in projection.agents {
        if agent.workItemId == Some(task.id) {
          return Some(agent)
        }
      }
      for agent in projection.agents {
        match
          energy_valley_runtime_task_for_agent_in_projection(projection, agent) {
          Some(resolved) if resolved.id == task.id => return Some(agent)
          _ => ()
        }
      }
      None
    }
  }
}

///|
fn town_chronicle_task_agent_id(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String? {
  town_chronicle_projected_agent_for_task(state, task).map(agent => agent.id)
}

///|
fn town_chronicle_task_agent_name(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String? {
  match town_chronicle_projected_agent_for_task(state, task) {
    Some(agent) => Some(agent.name)
    None if !(state.phase is Live) =>
      match task.agentName {
        Some(name) if !name.trim().is_empty() => Some(name)
        _ => None
      }
    None => None
  }
}

///|
fn town_chronicle_safe_task_title(task : EnergyValleyRuntimeWorkItem) -> String {
  energy_valley_safe_runtime_copy(
    task.title,
    "任务标题包含本地路径或过长内容，已隐藏",
    180,
  )
}

///|
fn town_chronicle_task_building_label(
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  exact_energy_valley_building_name(
    task.buildingModuleKey,
    task.bookId.unwrap_or(task.buildingModuleKey),
  )
}

///|
fn town_chronicle_live_title(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  let agent = town_chronicle_task_agent_name(state, task)
  let task_title = town_chronicle_safe_task_title(task)
  match task.status {
    "completed" => "已留下成果 · \{task_title}"
    "blocked" =>
      match agent {
        Some(name) => "\{name}的任务需要处理 · \{task_title}"
        None =>
          "\{town_chronicle_task_building_label(task)}的「\{task_title}」需要处理"
      }
    "failed" =>
      match agent {
        Some(name) => "\{name}的任务未完成 · \{task_title}"
        None =>
          "\{town_chronicle_task_building_label(task)}的「\{task_title}」未完成"
      }
    "waiting_review" =>
      "\{agent.unwrap_or(town_chronicle_task_building_label(task))}已把「\{task_title}」交给评审"
    "running" =>
      "\{agent.unwrap_or(town_chronicle_task_building_label(task))}正在推进「\{task_title}」"
    "assigned" =>
      "\{agent.unwrap_or(town_chronicle_task_building_label(task))}接下了「\{task_title}」"
    "queued" => "「\{task_title}」已进入任务队列"
    _ => task_title
  }
}

///|
fn town_chronicle_record_title(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  let task_title = town_chronicle_safe_task_title(task)
  if task.status == "completed" {
    "已记录成果 · \{task_title}"
  } else {
    match town_chronicle_task_agent_name(state, task) {
      Some(name) => "最近记录 · \{name} · \{task_title}"
      None => "最近记录 · \{task_title}"
    }
  }
}

///|
fn town_chronicle_task_title(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  if state.phase is Live {
    town_chronicle_live_title(state, task)
  } else {
    town_chronicle_record_title(state, task)
  }
}

///|
fn town_chronicle_task_participant_count(
  task : EnergyValleyRuntimeWorkItem,
) -> Int {
  match task.collaboration {
    Some(collaboration) => collaboration.participants.length()
    None => 0
  }
}

///|
fn town_chronicle_task_evidence_count(
  task : EnergyValleyRuntimeWorkItem,
) -> Int {
  task.resultLinks
  .unwrap_or([])
  .filter(energy_valley_runtime_result_link_is_valid)
  .length()
}

///|
fn town_chronicle_task_detail(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  let unsafe_recorded = match task.activityLabel {
    Some(label) if !label.trim().is_empty() => label
    _ =>
      match task.summary {
        Some(summary) if !summary.trim().is_empty() => summary
        _ => "任务 \{task.id} · \{town_chronicle_source_label(task.source)}"
      }
  }
  let recorded = energy_valley_safe_runtime_copy(
    unsafe_recorded, "活动描述包含本地路径或过长内容，已隐藏；请从允许的结果页核验。",
    180,
  )
  if state.phase is Live {
    recorded
  } else {
    "\{recorded}。最后快照状态为「\{town_chronicle_status_label(task.status)}」，不代表 Agent 现在仍在执行。"
  }
}

///|
fn town_chronicle_task_observed_at(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  match task.updatedAt {
    Some(value) if !value.trim().is_empty() => value
    _ =>
      match state.projection {
        Some(projection) => projection.observedAt
        None => "未记录时间"
      }
  }
}

///|
fn town_chronicle_entry_for_task(
  state : EnergyValleyRuntimeState,
  task : EnergyValleyRuntimeWorkItem,
) -> TownChronicleEntry {
  let live = state.phase is Live
  {
    source_label: town_chronicle_source_label(task.source),
    state_label: if live {
      town_chronicle_status_label(task.status)
    } else {
      "快照时 · \{town_chronicle_status_label(task.status)}"
    },
    tone: town_chronicle_task_tone(state, task),
    title: town_chronicle_task_title(state, task),
    detail: town_chronicle_task_detail(state, task),
    observed_at: town_chronicle_task_observed_at(state, task),
    agent_id: town_chronicle_task_agent_id(state, task),
    building_id: energy_valley_runtime_task_civic_id(task),
    evidence_count: town_chronicle_task_evidence_count(task),
    participant_count: town_chronicle_task_participant_count(task),
    task,
  }
}

///|
let town_chronicle_runtime_limit = 6

///|
fn town_chronicle_runtime_entries(
  state : EnergyValleyRuntimeState,
) -> Array[TownChronicleEntry] {
  let result : Array[TownChronicleEntry] = []
  match state.projection {
    None => ()
    Some(projection) => {
      let ordered = projection.tasks.map(task => task)
      ordered.sort_by((left, right) => {
        let by_time = right.updatedAt
          .unwrap_or("")
          .compare(left.updatedAt.unwrap_or(""))
        if by_time == 0 {
          right.id.compare(left.id)
        } else {
          by_time
        }
      })
      for task in ordered {
        if result.length() >= town_chronicle_runtime_limit {
          break
        }
        result.push(town_chronicle_entry_for_task(state, task))
      }
    }
  }
  result
}

///|
fn town_chronicle_history_groups(
  state : EnergyValleyRuntimeState,
) -> Array[TownChronicleHistoryGroup] {
  let groups : Array[TownChronicleHistoryGroup] = []
  let history = match state.projection {
    Some(projection) => projection.history.unwrap_or([])
    None => []
  }
  for task in history {
    let key = task.bookId.unwrap_or(task.buildingModuleKey)
    let mut found = false
    for group in groups {
      if group.key == key {
        group.tasks.push(task)
        found = true
        break
      }
    }
    if !found {
      groups.push({
        key,
        label: town_chronicle_task_building_label(task),
        building_id: energy_valley_runtime_task_civic_id(task),
        tasks: [task],
      })
    }
  }
  groups.sort_by((left, right) => left.label.compare(right.label))
  groups
}

///|
fn town_chronicle_history_count(
  groups : Array[TownChronicleHistoryGroup],
) -> Int {
  groups.fold(init=0, (count, group) => count + group.tasks.length())
}

///|
fn town_chronicle_runtime_evidence_count(
  state : EnergyValleyRuntimeState,
) -> Int {
  match state.projection {
    None => 0
    Some(projection) =>
      projection.tasks.fold(init=0, (count, task) => {
        count + town_chronicle_task_evidence_count(task)
      })
  }
}

///|
fn town_chronicle_phase_title(state : EnergyValleyRuntimeState) -> String {
  match state.phase {
    Live => "当前运行时账本"
    Stale => "最近一次真实快照"
    Loading => "正在读取小镇账本"
    Unavailable => "运行时尚未连接"
    Error => "小镇账本读取失败"
  }
}

///|
fn town_chronicle_phase_copy(state : EnergyValleyRuntimeState) -> String {
  match state.phase {
    Live =>
      "以当前耐久运行时投影为准；只有这里的执行中记录会被称为正在工作。"
    Stale =>
      "以下内容来自最近一次有效快照，可供回看，但不代表 Agent 现在仍在工作。"
    Loading =>
      "等待第一份耐久运行时投影；连接完成前不生成工作故事。"
    Unavailable =>
      "当前没有耐久运行时记录。地图装饰和演示居民不计为真实工作。"
    Error =>
      "无法读取耐久运行时投影；请检查本机服务日志。错误解决前不宣称有 Agent 正在工作。"
  }
}

///|
fn town_chronicle_phase_class(phase : EnergyValleyRuntimePhase) -> String {
  match phase {
    Live => "live"
    Stale => "stale"
    Loading => "loading"
    Unavailable => "unavailable"
    Error => "error"
  }
}

///|
fn town_chronicle_local_entry_from_line(
  line : String,
) -> TownChronicleLocalEntry? {
  let fields = line.split("|").to_array()
  if fields.length() < 3 {
    return None
  }
  let event = fields[1].to_owned()
  if !analytics_event_is_known(event) {
    return None
  }
  Some({
    day: fields[0].to_owned(),
    label: analytics_event_label(event),
    detail: fields[2].to_owned(),
  })
}

///|
fn town_chronicle_recent_local_entries(
  model : Model,
  limit : Int,
) -> Array[TownChronicleLocalEntry] {
  let result : Array[TownChronicleLocalEntry] = []
  if limit <= 0 {
    return result
  }
  for offset in 0..<model.analytics.length() {
    if result.length() >= limit {
      break
    }
    match
      town_chronicle_local_entry_from_line(
        model.analytics[model.analytics.length() - 1 - offset],
      ) {
      Some(entry) => result.push(entry)
      None => ()
    }
  }
  result
}

///|
fn town_chronicle_local_published_count(model : Model) -> Int {
  model.posts.filter(post => post.mine && post.published).length()
}

///|
fn render_town_chronicle_entry_action(
  dispatch : Dispatch[Msg],
  entry : TownChronicleEntry,
) -> @rabbita.Html {
  let actions : Array[@rabbita.Html] = []
  match entry.agent_id {
    Some(agent_id) =>
      actions.push(
        button(
          class="town-chronicle-action",
          on_click=dispatch(SelectAgent(agent_id)),
          attrs=@html.Attrs::build().aria_controls("resident-profile-panel"),
          "查看居民",
        ),
      )
    None => ()
  }
  if !entry.building_id.is_empty() {
    actions.push(
      button(
        class="town-chronicle-action",
        on_click=dispatch(OpenEnergyBuilding(entry.building_id)),
        "定位建筑",
      ),
    )
  }
  let evidence = entry.task.resultLinks
    .unwrap_or([])
    .filter(energy_valley_runtime_result_link_is_valid)
  if !evidence.is_empty() {
    actions.push(
      a(
        class="town-chronicle-action town-chronicle-evidence-action",
        href=evidence[0].url,
        "打开证据",
      ),
    )
  }
  div(class="town-chronicle-actions", actions)
}

///|
fn render_town_chronicle_audit(entry : TownChronicleEntry) -> @rabbita.Html {
  let run_id = entry.task.runId.unwrap_or("未记录")
  @html.details(class="town-chronicle-audit", [
    @html.summary(
      "核验记录 · \{entry.evidence_count} 份结果 · \{entry.participant_count} 位协作者",
    ),
    div(class="town-chronicle-audit-body", [
      p("任务 ID · \{entry.task.id}"),
      p("运行 ID · \{run_id}"),
      p("建筑 · \{entry.building_id}"),
      p("数据源 · \{entry.task.source}"),
      if entry.evidence_count > 0 {
        render_energy_valley_runtime_result_links(entry.task)
      } else {
        p(
          class="town-chronicle-no-evidence",
          "尚未记录可打开的结果页。",
        )
      },
    ]),
  ])
}

///|
fn render_town_chronicle_entry(
  dispatch : Dispatch[Msg],
  entry : TownChronicleEntry,
) -> @rabbita.Html {
  article(class="town-chronicle-entry town-chronicle-entry-\{entry.tone}", [
    div(class="town-chronicle-entry-head", [
      span(class="town-chronicle-source", entry.source_label),
      span(class="town-chronicle-state", entry.state_label),
    ]),
    h3(entry.title),
    p(class="town-chronicle-detail", entry.detail),
    p(class="town-chronicle-time", "记录时间 · \{entry.observed_at}"),
    render_town_chronicle_entry_action(dispatch, entry),
    render_town_chronicle_audit(entry),
  ])
}

///|
fn render_town_chronicle_history(
  dispatch : Dispatch[Msg],
  groups : Array[TownChronicleHistoryGroup],
) -> @rabbita.Html {
  if groups.is_empty() {
    return @html.nothing
  }
  let total = town_chronicle_history_count(groups)
  @html.details(class="town-chronicle-history", [
    @html.summary("历史重试债务 · \{total} 项"),
    div(class="town-chronicle-history-body", [
      p(
        class="town-chronicle-history-truth",
        "这些交接已终止，并被运行时明确归为临时基础设施重试债务；它们不计入当前 blocked/failed，也不构成完成证据。",
      ),
      div(
        class="town-chronicle-history-groups",
        groups.map(group => {
          div(class="town-chronicle-history-group", [
            div(class="town-chronicle-history-head", [
              div([
                span(class="town-chronicle-source", group.label),
                h3("\{group.tasks.length()} 项历史交接"),
              ]),
              button(
                class="town-chronicle-action",
                on_click=dispatch(OpenEnergyBuilding(group.building_id)),
                "定位建筑",
              ),
            ]),
            div(
              class="town-chronicle-history-list",
              group.tasks.map(task => {
                div(class="town-chronicle-history-row", [
                  span(
                    class="town-chronicle-history-title",
                    town_chronicle_safe_task_title(task),
                  ),
                  span(
                    class="town-chronicle-history-meta",
                    "历史状态 · \{town_chronicle_status_label(task.status)} · \{task.id}",
                  ),
                ])
              }),
            ),
          ])
        }),
      ),
    ]),
  ])
}

///|
fn render_town_chronicle_runtime_empty(
  state : EnergyValleyRuntimeState,
) -> @rabbita.Html {
  div(class="town-chronicle-empty", [
    h3(town_chronicle_phase_title(state)),
    p(town_chronicle_phase_copy(state)),
  ])
}

///|
fn render_town_chronicle_local(model : Model) -> @rabbita.Html {
  let entries = town_chronicle_recent_local_entries(model, 4)
  @html.details(class="town-chronicle-local", [
    @html.summary(
      "本机足迹 · 今日 \{analytics_today_activity(model)} 次操作",
    ),
    div(class="town-chronicle-local-body", [
      p(
        class="town-chronicle-local-truth",
        "仅来自当前浏览器，不代表多用户行为，也不代表真实 Agent 工作。",
      ),
      div(class="town-chronicle-local-stats", [
        span(
          "本机可分享标记 \{town_chronicle_local_published_count(model)}",
        ),
        span("本机收藏 \{collected_count(model)}"),
        span(
          "新手任务 \{quest_progress_count(model)}/\{town_quest_chain().length()}",
        ),
      ]),
      if entries.is_empty() {
        p(
          class="town-chronicle-local-empty",
          "当前浏览器还没有本机操作记录。",
        )
      } else {
        div(
          class="town-chronicle-local-list",
          entries.map(entry => {
            div(class="town-chronicle-local-entry", [
              span(class="town-chronicle-local-day", "第 \{entry.day} 天"),
              span(class="town-chronicle-local-label", entry.label),
              span(class="town-chronicle-local-detail", entry.detail),
            ])
          }),
        )
      },
    ]),
  ])
}

///|
/// Right-side "Town Today" drawer. It is intentionally non-modal so the map
/// remains visible; every story either navigates to a real Agent/building or
/// opens an allowlisted evidence page from the durable projection.
fn render_town_chronicle(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if !model.town_chronicle_open {
    return @html.nothing
  }
  let entries = town_chronicle_runtime_entries(model.energy_valley_runtime)
  let history_groups = town_chronicle_history_groups(
    model.energy_valley_runtime,
  )
  let history_count = town_chronicle_history_count(history_groups)
  let runtime_task_count = match model.energy_valley_runtime.projection {
    Some(projection) => projection.tasks.length()
    None => 0
  }
  let evidence_count = town_chronicle_runtime_evidence_count(
    model.energy_valley_runtime,
  )
  div(class="town-chronicle-layer", [
    aside(
      id="town-chronicle-panel",
      class="town-chronicle-panel pointer-events-auto",
      attrs=@html.Attrs::build()
        .role("dialog")
        .aria_modal("false")
        .aria_labelledby("town-chronicle-title"),
      [
        header(class="town-chronicle-head", [
          div([
            p(class="town-chronicle-kicker", "Town Today"),
            h2(id="town-chronicle-title", "今天，小镇发生了什么"),
          ]),
          button(
            class="town-chronicle-close",
            autofocus=true,
            on_click=dispatch(ToggleTownChronicle),
            attrs=@html.Attrs::build().aria_label("关闭小镇今日"),
            "×",
          ),
        ]),
        div(
          class="town-chronicle-phase town-chronicle-phase-\{town_chronicle_phase_class(model.energy_valley_runtime.phase)}",
          [
            span(class="town-chronicle-phase-dot", ""),
            div([
              span(
                class="town-chronicle-phase-title",
                town_chronicle_phase_title(model.energy_valley_runtime),
              ),
              p(town_chronicle_phase_copy(model.energy_valley_runtime)),
            ]),
          ],
        ),
        div(class="town-chronicle-metrics", [
          span("当前账本任务 \{runtime_task_count}"),
          if history_count > 0 {
            span("历史重试 \{history_count}")
          } else {
            @html.nothing
          },
          span("可打开结果 \{evidence_count}"),
          span("本机今日 \{analytics_today_activity(model)}"),
        ]),
        section(class="town-chronicle-stream", [
          if entries.is_empty() {
            render_town_chronicle_runtime_empty(model.energy_valley_runtime)
          } else {
            div(
              class="town-chronicle-entry-list",
              entries.map(entry => render_town_chronicle_entry(dispatch, entry)),
            )
          },
        ]),
        render_town_chronicle_history(dispatch, history_groups),
        render_town_chronicle_local(model),
        p(
          class="town-chronicle-footnote",
          "当前任务与历史重试由同一份运行时投影分栏；历史债务不冒充当前阻塞，演示居民不进入此处。",
        ),
      ],
    ),
  ])
}
