///|
pub fn story_forge_pattern() -> CivicCommunicationPattern {
  {
    id: "story-forge",
    title: "Story Forge",
    category: "narrative-synthesis",
    summary: "Events, interviews, photos, and outcomes are gathered into public-safe stories with reviewable claims.",
    protocol_mode: "collect-synthesize-publish",
    input_contract: "story evidence packet",
    reduction_contract: "story draft",
    output_contract: "civic.story.publication.v1",
    review_contract: "consent, accuracy, tone, public value",
    cadence_hint: "after events or weekly",
    good_for: [
      "community storytelling", "case studies", "public progress pages",
    ],
    civic_examples: [
      "Wenyu town chronicle", "founder story wall", "event recap desk",
    ],
  }
}

///|
pub fn incident_bridge_pattern() -> CivicCommunicationPattern {
  {
    id: "incident-bridge",
    title: "Incident Bridge",
    category: "real-world-coordination",
    summary: "Operational signals, human reports, and physical-world gateways are coordinated into status, escalation, and recovery actions.",
    protocol_mode: "sense-coordinate-recover",
    input_contract: "incident/status packet",
    reduction_contract: "coordination plan",
    output_contract: "civic.incident.bridge.v1",
    review_contract: "urgency, safety, owner, recovery status",
    cadence_hint: "real-time while active",
    good_for: [
      "physical bridge operations", "robotics demos", "onsite incidents",
    ],
    civic_examples: [
      "robot demo bridge", "venue operations bridge", "field telemetry desk",
    ],
  }
}
