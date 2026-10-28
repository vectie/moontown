///|
fn render_town_shell_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model, "town-shell", "Town Shell", "查看已载入的任务和业务记录。建筑动画不代表真实工作正在运行。",
    "进入建筑查看任务和结果。",
  )
}

///|
fn render_vitality_dashboard_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model, "vitality-dashboard", "Vitality Dashboard", "活力统计尚未接入真实居民、积分、活动和服务响应数据。",
    "任务进度以运行记录为准。",
  )
}

///|
fn render_contest_express_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model,
    "contest-express",
    "Contest Express",
    "赛事日程、报名、提交和评审统一在赛事工作台查看。",
    "以赛事公布的截止时间和审核结果为准。",
    details=[
      a(
        href="./hackathon.html",
        class="quest-next",
        "打开赛事工作台 ↗",
      ),
    ],
  )
}

///|
fn render_physical_bridge_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model,
    "physical-bridge",
    "Physical Bridge",
    "场地、机器人与实时遥测尚未接入。这里展示线下交接方案。",
    "确认服务方与授权后，才能执行线下动作。",
    details=[
      render_module_detail("设备", physical_bridge_coverage_label(model)),
    ],
  )
}
