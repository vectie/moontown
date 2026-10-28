///|
fn social_matches() -> Array[SocialMatchSim] {
  [
    {
      left: "Li / Edge AI OPC",
      right: "Chen / Design Automation OPC",
      reason: "Hardware prototype needs investor-facing UI and demo storytelling.",
      next_step: "示例：双方同意后再安排介绍，尚未发送邀请。",
    },
    {
      left: "AI Garden Tutor",
      right: "Policy Sprite",
      reason: "Daily AI tip can explain subsidy form filling with a practical demo.",
      next_step: "示例：先核对政策来源，再准备教程草稿。",
    },
  ]
}

///|
fn talent_signals(model : Model) -> Array[TalentSignalSim] {
  ignore(model)
  [
    {
      name: "Edge AI Studio",
      domain: "Robotics / edge vision",
      project: "Low-power orchard camera pilot",
      skills: "TinyML, camera modules, deployment",
      recent_achievement: "示例项目：低功耗果园传感器，尚未接入验证记录。",
      evidence_status: "示例 · 未认证",
      reception_note: "示例路线第一站：了解硬件项目。",
      activity: 0,
    },
    {
      name: "Design Automation Lab",
      domain: "AI design services",
      project: "Prompt-to-prototype studio sprint",
      skills: "UI generation, design systems, rapid prototypes",
      recent_achievement: "示例项目：创始人界面设计，尚未接入交付记录。",
      evidence_status: "示例 · 未认证",
      reception_note: "示例路线第二站：了解软件服务。",
      activity: 0,
    },
    {
      name: "Policy Ops Desk",
      domain: "District services",
      project: "Founder reception routing pilot",
      skills: "policy synthesis, reception routes, event ops",
      recent_achievement: "示例场景：整理来访问题，不代表发生过真实接待。",
      evidence_status: "示例 · 未认证",
      reception_note: "示例路线第三站：讨论服务需求。",
      activity: 0,
    },
  ]
}
