///|
fn resident_sims(model : Model) -> Array[ResidentSim] {
  [
    {
      name: "Li / Edge AI OPC",
      venture: "Low-power vision module studio",
      need: "Needs rental subsidy eligibility and contest prep.",
      mood: if model.pressure > 70 {
        "Focused"
      } else {
        "Curious"
      },
      agent_goal: "Ask Policy Sprite for subsidy checklist, then book a mock roadshow.",
      memory: "Remembered a past concern about compute vouchers and prototype demo timing.",
      reflection: "Confidence rises when policy advice turns into a concrete checklist and rehearsal slot.",
      plan: "09:00 policy quest, 14:00 cafe intro, 18:00 reflection note.",
      recent_action: "Policy Sprite drafted a subsidy checklist and queued a mock roadshow packet.",
      privacy_scope: "Operator summary",
      zone: "Policy Hall",
    },
    {
      name: "Chen / Design Automation OPC",
      venture: "AI UI prototyping service",
      need: "Looking for hardware founders who need interface design.",
      mood: "Open to weak-tie match",
      agent_goal: "Meet one robotics or edge-AI neighbor in Social Square.",
      memory: "Prefers low-pressure cafe intros before business collaboration.",
      reflection: "Warm introductions outperform cold outreach when social pressure stays low and goals are specific.",
      plan: "Browse Talent Avenue, accept cafe match, save follow-up memory.",
      recent_action: "Cafe Matchmaker proposed a founder intro with a shared demo-day preparation angle.",
      privacy_scope: "Shared town",
      zone: "Social Square",
    },
    {
      name: "Ma / Policy Ops Visitor",
      venture: "District operator evaluating settlement conversion.",
      need: "Needs tour-ready talent graph and daily vitality summary.",
      mood: "Observing",
      agent_goal: "Generate VIP reception route and verify achievement broadcasts.",
      memory: "Asked yesterday for warm-community evidence instead of raw traffic.",
      reflection: "Operator trust improves when the town shows story-rich resident progress instead of abstract metrics alone.",
      plan: "Review talent heatmap, export visit notes, flag missing service gaps.",
      recent_action: "Talent Avenue projected a tour summary while keeping resident-private notes out of the route brief.",
      privacy_scope: "Public-safe",
      zone: "Talent Avenue",
    },
  ]
}
