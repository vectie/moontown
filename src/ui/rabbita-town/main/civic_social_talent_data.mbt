///|
fn social_matches() -> Array[SocialMatchSim] {
  [
    {
      left: "Li / Edge AI OPC",
      right: "Chen / Design Automation OPC",
      reason: "Hardware prototype needs investor-facing UI and demo storytelling.",
      next_step: "Cafe intro at 15:30, then shared roadshow checklist.",
      confidence: 87,
    },
    {
      left: "AI Garden Tutor",
      right: "Policy Sprite",
      reason: "Daily AI tip can explain subsidy form filling with a practical demo.",
      next_step: "Publish tutorial quest after policy source review.",
      confidence: 79,
    },
  ]
}

///|
fn talent_signals(model : Model) -> Array[TalentSignalSim] {
  [
    {
      name: "Edge AI Studio",
      domain: "Robotics / edge vision",
      project: "Low-power orchard camera pilot",
      skills: "TinyML, camera modules, deployment",
      recent_achievement: "Verified a low-power orchard sensor demo for the district tour route.",
      evidence_status: "Verified evidence",
      reception_note: "Start the VIP route here to show shipping hardware and calm operator notes.",
      activity: clamp_metric(72 + model.tick % 16),
    },
    {
      name: "Design Automation Lab",
      domain: "AI design services",
      project: "Prompt-to-prototype studio sprint",
      skills: "UI generation, design systems, rapid prototypes",
      recent_achievement: "Published a reusable service blueprint for founder-facing UI demos.",
      evidence_status: "Review queued",
      reception_note: "Use as the second stop when the tour needs a fast software contrast.",
      activity: clamp_metric(66 + model.tick % 19),
    },
    {
      name: "Policy Ops Desk",
      domain: "District services",
      project: "Founder reception routing pilot",
      skills: "policy synthesis, reception routes, event ops",
      recent_achievement: "Turned yesterday's visitor questions into a public-safe route brief.",
      evidence_status: "Projection-safe summary",
      reception_note: "Close the route with this card to connect public talent signals to operator workflow.",
      activity: clamp_metric(58 + model.tick % 23),
    },
  ]
}
