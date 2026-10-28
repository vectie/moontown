///|
fn civic_quests(model : Model) -> Array[CivicQuestSim] {
  [
    {
      title: "昌平政策梳理",
      area: "Policy Hall",
      stage: "从问题与来源开始",
      reward: "",
      status: civic_surface_status(model, "policy-hall"),
      status_class: "module-signal-neutral",
      detail: civic_surface_evidence(model, "policy-hall"),
      next_action: "进入政策大厅提问；申请条件仍需向主管部门核实。",
    },
    {
      title: "赛事与提交",
      area: "Contest Express",
      stage: "赛事工作台",
      reward: "",
      status: "查看赛事",
      status_class: "module-signal-neutral",
      detail: "报名、截止时间、提交回执和排名以赛事工作台为准。",
      next_action: "选择赛事，查看你能参与的下一步。",
    },
    {
      title: "合作介绍示例",
      area: "Social Square",
      stage: "示例方案",
      reward: "",
      status: "示例",
      status_class: "module-signal-neutral",
      detail: "尚未发送邀请或安排见面。",
      next_action: "真实介绍需要双方同意。",
    },
    {
      title: "AI 学习任务示例",
      area: "AI Garden",
      stage: "示例方案",
      reward: "",
      status: "示例",
      status_class: "module-signal-neutral",
      detail: "展示学习任务思路，不代表工具已执行或学习测评已完成。",
      next_action: "选择学习问题，准备可核对的材料。",
    },
    {
      title: "线下服务交接",
      area: "Physical Bridge",
      stage: "服务未接入",
      reward: "",
      status: "未接入",
      status_class: "module-signal-neutral",
      detail: "尚未接通真实场地、机器人或遥测。",
      next_action: "执行前需服务方确认与授权。",
    },
  ]
}

///|
fn render_quest_card(quest : CivicQuestSim) -> @rabbita.Html {
  article(class="quest-card", [
    p(class="scene-node-key", quest.area),
    h3(quest.title),
    span(class="module-signal \{quest.status_class}", quest.status),
    p(class="quest-detail", quest.detail),
    p(class="quest-next", quest.next_action),
    if quest.area == "Contest Express" {
      a(
        href="./hackathon.html",
        class="quest-next",
        "打开赛事工作台 ↗",
      )
    } else {
      @html.nothing
    },
  ])
}

///|
fn render_civic_quests(model : Model) -> @rabbita.Html {
  section(class="quest-panel", [
    div(class="runtime-copy", [h2("服务与任务")]),
    div(class="quest-grid", civic_quests(model).map(render_quest_card)),
  ])
}
