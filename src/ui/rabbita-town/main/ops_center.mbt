///|
/// A truthful projection of the optional real runtime. Counts may be shown
/// from a stale snapshot, but the phase label always makes that explicit.
priv struct OpsRuntimeMetrics {
  phase : String
  agents : Int
  tasks : Int
  active : Int
  completed : Int
  blocked : Int
}

///|
fn svg_escape_text(text : String) -> String {
  text
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
}

///|
fn chart_max(values : Array[Int]) -> Int {
  let mut max = 1
  for value in values {
    if value > max {
      max = value
    }
  }
  max
}

///|
fn chart_sum(values : Array[Int]) -> Int {
  let mut total = 0
  for value in values {
    total += value
  }
  total
}

///|
fn svg_accessibility(title : String, description : String) -> String {
  "<title>\{svg_escape_text(title)}</title>" +
  "<desc>\{svg_escape_text(description)}</desc>"
}

///|
fn svg_trend_chart(
  values : Array[Int],
  color : String,
  title : String,
  description : String,
) -> String {
  let width = 560
  let height = 172
  let pad = 30
  let max = chart_max(values)
  let denominator = if values.length() > 1 { values.length() - 1 } else { 1 }
  let step = (width - pad * 2).to_double() / denominator.to_double()
  let points : Array[String] = []
  let mut labels = ""
  for index, value in values {
    let x = pad + (index.to_double() * step).to_int()
    let y = height - 34 - value * (height - 66) / max
    points.push("\{x},\{y}")
    labels = labels +
      "<text x=\"\{x}\" y=\"\{height - 12}\" fill=\"#94a3b8\" font-size=\"10\" text-anchor=\"middle\">-\{values.length() - 1 - index}日</text>" +
      "<text x=\"\{x}\" y=\"\{y - 8}\" fill=\"#e2e8f0\" font-size=\"10\" text-anchor=\"middle\">\{value}</text>"
  }
  let line = points.join(" ")
  let first_x = pad
  let last_x = pad + ((values.length() - 1).to_double() * step).to_int()
  "<svg viewBox=\"0 0 \{width} \{height}\" class=\"ops-chart-svg\" role=\"img\" aria-label=\"\{svg_escape_text(title)}\">" +
  svg_accessibility(title, description) +
  "<polygon points=\"\{first_x},\{height - 34} \{line} \{last_x},\{height - 34}\" fill=\"\{color}\" opacity=\"0.12\"/>" +
  "<polyline points=\"\{line}\" fill=\"none\" stroke=\"\{color}\" stroke-width=\"2.5\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>" +
  labels +
  "</svg>"
}

///|
fn svg_bar_chart(
  values : Array[Int],
  labels : Array[String],
  color : String,
  title : String,
  description : String,
) -> String {
  let width = 560
  let height = 178
  let pad = 30
  let max = chart_max(values)
  let slots = if values.is_empty() { 1 } else { values.length() }
  let slot = (width - pad * 2) / slots
  let bar_width = (slot * 3 / 5).max(4)
  let mut bars = ""
  for index, value in values {
    let x = pad + index * slot + (slot - bar_width) / 2
    let calculated = value * (height - 72) / max
    let h = if value == 0 { 1 } else { calculated.max(2) }
    let y = height - 42 - h
    let label = labels.get(index).unwrap_or("")
    bars = bars +
      "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{bar_width}\" height=\"\{h}\" rx=\"3\" fill=\"\{color}\" opacity=\"\{if value == 0 { 0.25 } else { 0.78 }}\"/>" +
      "<text x=\"\{x + bar_width / 2}\" y=\"\{y - 7}\" fill=\"#e2e8f0\" font-size=\"11\" text-anchor=\"middle\">\{value}</text>" +
      "<text x=\"\{x + bar_width / 2}\" y=\"\{height - 16}\" fill=\"#94a3b8\" font-size=\"10\" text-anchor=\"middle\">\{svg_escape_text(label)}</text>"
  }
  "<svg viewBox=\"0 0 \{width} \{height}\" class=\"ops-chart-svg\" role=\"img\" aria-label=\"\{svg_escape_text(title)}\">" +
  svg_accessibility(title, description) +
  bars +
  "</svg>"
}

///|
fn svg_journey_chart(stages : Array[(String, Int)]) -> String {
  let mut rows = ""
  for index, stage in stages {
    let (label, value) = stage
    let y = index * 34
    let completed = value == 1
    let fill = if completed { "#34d399" } else { "#475569" }
    let state = if completed { "已完成" } else { "待完成" }
    let width = if completed { 380 } else { 18 }
    rows = rows +
      "<text x=\"0\" y=\"\{y + 16}\" fill=\"#cbd5e1\" font-size=\"12\">\{svg_escape_text(label)}</text>" +
      "<rect x=\"100\" y=\"\{y}\" width=\"\{width}\" height=\"22\" rx=\"6\" fill=\"\{fill}\" opacity=\"0.85\"/>" +
      "<text x=\"490\" y=\"\{y + 16}\" fill=\"#f8fafc\" font-size=\"12\">\{state}</text>"
  }
  let completed = stages.filter(stage => stage.1 == 1).length()
  let description = "当前本机角色已完成 \{completed}/\{stages.length()} 个旅程步骤；这不是多用户转化漏斗。"
  "<svg viewBox=\"0 0 560 \{stages.length() * 34}\" class=\"ops-chart-svg\" role=\"img\" aria-label=\"当前角色旅程\">" +
  svg_accessibility("当前角色旅程", description) +
  rows +
  "</svg>"
}

///|
fn ops_runtime_metrics(model : Model) -> OpsRuntimeMetrics {
  let phase = match model.energy_valley_runtime.phase {
    Loading => "正在连接"
    Live => "实时"
    Stale => "过期快照"
    Unavailable => "未连接"
    Error => "读取错误"
  }
  match model.energy_valley_runtime.projection {
    None => { phase, agents: 0, tasks: 0, active: 0, completed: 0, blocked: 0 }
    Some(projection) => {
      let mut active = 0
      let mut completed = 0
      let mut blocked = 0
      for task in projection.tasks {
        match task.status {
          "queued" | "assigned" | "running" | "waiting_review" => active += 1
          "completed" => completed += 1
          "failed" | "blocked" => blocked += 1
          _ => ()
        }
      }
      {
        phase,
        agents: projection.agents.length(),
        tasks: projection.tasks.length(),
        active,
        completed,
        blocked,
      }
    }
  }
}

///|
fn ops_metric_card(
  label : String,
  value : String,
  detail : String,
) -> @rabbita.Html {
  div(class="ops-metric", [
    div(class="ops-metric-label", label),
    div(class="ops-metric-value", value),
    div(class="ops-metric-delta", detail),
  ])
}

///|
fn ops_runtime_report_fragment(model : Model) -> String {
  let runtime = ops_runtime_metrics(model)
  "真实运行时（\{runtime.phase}）：Agent \{runtime.agents} · 工作项 \{runtime.tasks} · 活跃 \{runtime.active} · 完成 \{runtime.completed} · 阻塞/失败 \{runtime.blocked}"
}

///|
fn ops_report_line_for_day(model : Model, day : Int) -> String {
  let activity = analytics_event_count_on(model, day)
  let builds = analytics_count_on(model, day, "build_place")
  let sent = analytics_count_on(model, day, "phone_send")
  let replies = analytics_count_on(model, day, "phone_receive")
  let mine = model.posts.filter(post => post.mine).length()
  let published = model.posts
    .filter(post => post.mine && post.published)
    .length()
  let collected = collected_count(model)
  "第\{day}天 · 本机活动 \{activity} 条 · 建造 \{builds} 次 · 本地剧本消息 发送\{sent}/回复\{replies} · 生成时本地知识 我的\{mine}/发布\{published}/收藏\{collected} · 生成时谷光余额 \{model.spark} · 生成时\{ops_runtime_report_fragment(model)}"
}

///|
fn ops_report_line(model : Model) -> String {
  ops_report_line_for_day(model, energy_valley_sim_day(model))
}

///|
/// Append a truthful local/runtime snapshot for every game day that has just
/// ended. The persisted marker stores the tick of the last report, so reloads
/// and animation-frame frequency cannot create duplicate "daily" reports.
/// Reports are deliberately described as locally persisted snapshots, not
/// scheduled external delivery: there is no reporting backend or delivery
/// channel.
fn ops_maybe_scheduled_report(model : Model) -> Model {
  if model.tick <= 0 {
    return model
  }
  let current_day = energy_valley_sim_day(model)
  let last_report_day = energy_valley_sim_day({
    ..model,
    tick: model.last_report_tick,
  })
  if current_day <= last_report_day {
    return model
  }
  let mut next = model
  for ended_day in last_report_day..<current_day {
    next = town_life_append_scheduled_ops_report(
      next,
      "scheduled-report:\{active_energy_valley_seed()}:\{ended_day}",
      ops_report_line_for_day(model, ended_day),
    )
  }
  { ..next, last_report_tick: model.tick }
}

///|
fn render_ops_chart(
  title : String,
  chart : String,
  summary : String,
) -> @rabbita.Html {
  div(class="ops-card", [
    div(class="ops-card-title", title),
    div(attrs=@html.Attrs::build().inner_html(chart), no_children()),
    p(class="ops-footnote", summary),
  ])
}

///|
fn render_ops_source_legend(model : Model) -> @rabbita.Html {
  let runtime = ops_runtime_metrics(model)
  div(class="ops-card", [
    div(class="ops-card-title", "数据来源与边界"),
    div(class="ops-event-list", [
      div(
        class="ops-event-row",
        "本机记录 · localStorage 环形缓冲 · \{model.analytics.length()}/\{analytics_ring_capacity} 条",
      ),
      div(
        class="ops-event-row",
        "真实运行时 · \{runtime.phase} · Agent \{runtime.agents} / 工作项 \{runtime.tasks}",
      ),
      div(
        class="ops-event-row",
        "演示内容 · 广场居民、人才和机构示例 · 不进入活跃、留存或运行时指标",
      ),
    ]),
  ])
}

///|
fn render_ops_overview(model : Model) -> @rabbita.Html {
  let activity_series = analytics_activity_series(model, 7)
  let categories = analytics_today_categories(model)
  let category_values = categories.map(item => item.1)
  let category_labels = categories.map(item => item.0)
  let journey = analytics_funnel(model)
  let runtime = ops_runtime_metrics(model)
  let runtime_values = [
    runtime.agents,
    runtime.tasks,
    runtime.active,
    runtime.completed,
    runtime.blocked,
  ]
  let runtime_labels = ["Agent", "工作项", "活跃", "完成", "阻塞"]
  let knowledge = analytics_local_knowledge_counts(model)
  let knowledge_values = knowledge.map(item => item.1)
  let knowledge_labels = knowledge.map(item => item.0)
  div(class="ops-grid", [
    render_ops_source_legend(model),
    div(class="ops-metrics", [
      ops_metric_card(
        "本机本游戏日活动",
        "\{analytics_today_activity(model)}",
        "事件条数，不是 DAU",
      ),
      ops_metric_card(
        "近 7 游戏日有记录",
        "\{analytics_active_recorded_days(model, 7)} 天",
        "本机档案，不是留存率",
      ),
      ops_metric_card(
        "本日建造",
        "\{analytics_today_builds(model)} 次",
        "来自 build_place",
      ),
      ops_metric_card(
        "本地剧本消息",
        "\{analytics_today_chats(model)} 条",
        "发送 \{analytics_today_chat_sent(model)} / 回复 \{analytics_today_chat_replies(model)}",
      ),
      ops_metric_card(
        "真实运行时 Agent",
        "\{runtime.agents}",
        runtime.phase,
      ),
    ]),
    render_ops_chart(
      "视图 1 · 本机活动（最近 7 个游戏日）",
      svg_trend_chart(
        activity_series,
        "#38bdf8",
        "本机最近七个游戏日活动",
        "每天的本地事件条数依次为 \{activity_series.map(value => "\{value}").join(", ")}。",
      ),
      "共 \{chart_sum(activity_series)} 条本机事件，\{analytics_active_recorded_days(model, 7)}/7 个游戏日有记录。零值保持为零，未混入演示基线。",
    ),
    render_ops_chart(
      "视图 2 · 本日行为构成",
      svg_bar_chart(
        category_values, category_labels, "#f2c94c", "本日行为构成", "本日引导、探索、本地社交、建造、知识和系统事件的精确计数。",
      ),
      "这 \{chart_sum(category_values)} 条行为均来自当前浏览器档案；本地剧本聊天不计作真实 Agent 对话。",
    ),
    render_ops_chart(
      "视图 3 · 当前角色旅程（不是多用户漏斗）",
      svg_journey_chart(journey),
      "当前本机角色完成 \{analytics_funnel_completed(model)}/7 步。缺少用户标识和会话标识，因此不声称转化率。",
    ),
    render_ops_chart(
      "视图 4 · 真实运行时快照",
      svg_bar_chart(
        runtime_values,
        runtime_labels,
        "#34d399",
        "真实运行时快照",
        ops_runtime_report_fragment(model),
      ),
      "\{ops_runtime_report_fragment(model)}。只有标为“实时”时才代表当前工作；过期快照仅供追溯。",
    ),
    render_ops_chart(
      "视图 5 · 本地知识资产",
      svg_bar_chart(
        knowledge_values, knowledge_labels, "#c084fc", "本地知识资产", "我的条目、已发布条目、已收藏条目、自建楼宇和广场示例的本地计数。",
      ),
      "“广场示例”是随产品提供的演示内容；其余计数来自本机模型。发布和收藏目前不是网络共享数据。",
    ),
  ])
}

///|
fn analytics_event_display(line : String) -> String {
  let fields = line.split("|").to_array()
  if fields.length() < 2 {
    return line
  }
  let event = fields[1].to_owned()
  let label = analytics_event_label(event)
  "\{line} · \{label}"
}

///|
fn render_ops_events(model : Model) -> @rabbita.Html {
  let events : Array[@rabbita.Html] = []
  let start = if model.analytics.length() > 40 {
    model.analytics.length() - 40
  } else {
    0
  }
  let mut index = model.analytics.length() - 1
  while index >= start {
    events.push(
      div(
        class="ops-event-row",
        analytics_event_display(model.analytics[index]),
      ),
    )
    index -= 1
  }
  if events.is_empty() {
    events.push(
      p(
        class="square-empty",
        "还没有本机活动记录。创建角色、行走或发一条本地剧本消息后，事件会出现在这里。",
      ),
    )
  }
  let dictionary = analytics_event_dictionary().map(definition => {
    div(
      class="ops-event-row",
      "\{definition.name} · \{definition.label} · \{definition.category}",
    )
  })
  div(class="ops-grid", [
    div(class="ops-card", [
      div(
        class="ops-card-title",
        "本机事件流（最近 40 条 · 日|事件|详情）",
      ),
      div(class="ops-event-list", events),
    ]),
    div(class="ops-card", [
      div(
        class="ops-card-title",
        "权威事件字典 \{analytics_event_dictionary_version()}",
      ),
      p(
        class="ops-footnote",
        "未知事件会在写入时被拒绝，避免 19/20 种定义漂移。",
      ),
      div(class="ops-event-list", dictionary),
    ]),
  ])
}

///|
fn render_ops_reports(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let rows = model.ops_reports.map(line => div(class="ops-event-row", line))
  div(class="ops-card", [
    div(
      class="ops-card-title",
      "本页运营快照（每个游戏日自动生成）",
    ),
    p(
      class="ops-footnote",
      "快照只汇总本机活动与明确标记阶段的真实运行时数据；正文随本机小镇生活存档保存，不会冒充 DAU、留存或已送达的外部日报。",
    ),
    button(
      class="square-action",
      on_click=dispatch(OpsGenerateReport),
      "生成当前快照",
    ),
    div(
      class="ops-event-list",
      if rows.is_empty() {
        [
          p(
            class="square-empty",
            "尚无快照。点上方按钮立即生成，或等下一个游戏日自动生成。",
          ),
        ]
      } else {
        rows
      },
    ),
  ])
}

///|
fn ops_talent_pool() -> Array[(String, String, String)] {
  [
    (
      "🧠", "林知微 · Agent 架构师", "演示档案：擅长多智能体编排，想找真实运行时项目",
    ),
    (
      "🎨", "陆青梧 · 像素美术", "演示档案：等距场景 / 角色行走图，希望参与皮肤共建",
    ),
    (
      "📈", "赵一麦 · 社区运营", "演示档案：做过社区冷启动，可讨论增长打法",
    ),
    (
      "🔬", "何雁回 · 能源研究员", "演示档案：零碳楼宇方向，想开一栋研究塔楼",
    ),
  ]
}

///|
fn ops_company_showcase() -> Array[(String, String)] {
  [
    (
      "🏢 谷光智能", "演示机构卡，不代表真实入驻或招聘关系",
    ),
    (
      "⚡ 未来能源联合实验室", "演示机构卡，不代表已接入真实课题",
    ),
    ("🚇 17 号线通勤社", "演示社区卡，不代表真实活动排期"),
  ]
}

///|
fn render_ops_growth() -> @rabbita.Html {
  div(class="ops-grid", [
    div(class="ops-card", [
      div(class="ops-card-title", "共建活动构想（演示，未投放）"),
      p(
        class="ops-footnote",
        "以下是运营策划样稿，不是实时广告、奖励承诺或已上线活动。",
      ),
      div(class="ops-ad", [
        div(class="ops-ad-head", "「盖一栋楼，留一个名字」"),
        p(
          class="wizard-copy",
          "概念稿：发布首栋知识大楼后进入镇志候选。",
        ),
      ]),
      div(class="ops-ad", [
        div(class="ops-ad-head", "17 号线通勤礼包"),
        p(
          class="wizard-copy",
          "概念稿：待真实邀请与账户系统接入后启用。",
        ),
      ]),
    ]),
    div(class="ops-card", [
      div(
        class="ops-card-title",
        "人才档案示例（邀请通道未接入）",
      ),
      div(
        class="ops-talent-list",
        ops_talent_pool().map(talent => {
          let (glyph, name, bio) = talent
          div(class="ops-talent", [
            span(class="phone-contact-avatar", glyph),
            span(class="phone-contact-meta", [
              span(class="phone-contact-name", name),
              span(class="phone-contact-last", bio),
            ]),
            button(
              class="square-action",
              disabled=true,
              attrs=@html.Attrs::build()
                .aria_disabled("true")
                .aria_label("邀请通道尚未接入"),
              "邀请未开放",
            ),
          ])
        }),
      ),
    ]),
    div(class="ops-card", [
      div(class="ops-card-title", "公司 / 机构展示样稿"),
      div(
        class="ops-talent-list",
        ops_company_showcase().map(company => {
          let (name, copy) = company
          div(class="ops-talent", [
            span(class="phone-contact-meta", [
              span(class="phone-contact-name", name),
              span(class="phone-contact-last", copy),
            ]),
          ])
        }),
      ),
    ]),
  ])
}

///|
fn render_ops_center(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  if !model.ops_open {
    return @html.nothing
  }
  let tab_button = fn(index : Int, label : String) -> @rabbita.Html {
    button(
      class=if model.ops_tab == index {
        "ops-tab ops-tab-active"
      } else {
        "ops-tab"
      },
      on_click=dispatch(SetOpsTab(index)),
      attrs=@html.Attrs::build().aria_pressed(
        if model.ops_tab == index {
          "true"
        } else {
          "false"
        },
      ),
      label,
    )
  }
  div(
    class="absolute inset-0 z-40 flex items-center justify-center bg-slate-950/70 p-4",
    [
      section(
        class="ops-panel pointer-events-auto",
        attrs=@html.Attrs::build()
          .role("dialog")
          .aria_modal("true")
          .aria_labelledby("ops-panel-title"),
        [
          div(class="ops-panel-head", [
            span(
              id="ops-panel-title",
              class="square-panel-title",
              "能源谷运营中心",
            ),
            button(
              class="phone-panel-close",
              on_click=dispatch(ToggleOps),
              attrs=@html.Attrs::build().aria_label("关闭运营中心"),
              "✕",
            ),
          ]),
          div(class="ops-tabs", [
            tab_button(0, "概览"),
            tab_button(1, "本机事件"),
            tab_button(2, "运营快照"),
            tab_button(3, "策划样稿"),
          ]),
          div(class="ops-panel-body", [
            if model.ops_tab == 0 {
              render_ops_overview(model)
            } else if model.ops_tab == 1 {
              render_ops_events(model)
            } else if model.ops_tab == 2 {
              render_ops_reports(dispatch, model)
            } else {
              render_ops_growth()
            },
          ]),
          p(
            class="ops-footnote",
            "本机活动、真实运行时和演示内容始终分开呈现；当前数据不足以计算 DAU、留存率或多用户转化率。",
          ),
        ],
      ),
    ],
  )
}
