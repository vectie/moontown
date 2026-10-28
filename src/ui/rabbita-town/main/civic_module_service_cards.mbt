///|
fn render_policy_hall_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model,
    "policy-hall",
    "Policy Hall",
    "从本地议题、来源和材料开始；当前专题主要覆盖青年创业。",
    "进入政策大厅，说明你的问题。",
    details=[
      render_module_detail(
        "证据",
        civic_surface_evidence(model, "policy-hall"),
      ),
    ],
  )
}

///|
fn render_resident_twins_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model, "resident-twins", "Resident Twins", "示例居民展示需求和个人计划，不是已授权的真实用户资料。",
    "个人资料与记忆服务尚未接入。",
  )
}

///|
fn render_social_square_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model, "social-square", "Social Square", "浏览合作方向和介绍理由；示例不会发送邀请或安排见面。",
    "真实介绍需要双方同意。",
  )
}

///|
fn render_talent_avenue_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model, "talent-avenue", "Talent Avenue", "人才卡与接待路线为示例，未作真实资质认证。",
    "真实人才资料与验证记录尚未接入。",
  )
}

///|
fn render_ai_garden_module_card(model : Model) -> @rabbita.Html {
  render_civic_service_card(
    model, "ai-garden", "AI Garden", "探索 AI 学习任务示例；尚无真实工具试用或学习测评记录。",
    "先选择学习问题，再准备材料。",
  )
}
