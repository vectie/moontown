///|
pub struct CivicCommunicationPattern {
  id : String
  title : String
  category : String
  summary : String
  protocol_mode : String
  input_contract : String
  reduction_contract : String
  output_contract : String
  review_contract : String
  cadence_hint : String
  good_for : Array[String]
  civic_examples : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn civic_communication_patterns() -> Array[CivicCommunicationPattern] {
  [
    {
      id: "research-salon",
      title: "Research Salon",
      category: "knowledge-exchange",
      summary: "Many specialist workspaces exchange perspectives, reduce tensions into research questions, and return follow-up ideas home.",
      protocol_mode: "exchange-reduce-distribute",
      input_contract: "perspective packet",
      reduction_contract: "cross-area idea reduction",
      output_contract: "civic.salon.idea_reduction.v1",
      review_contract: "novelty, feasibility, evidence gap, owner workspace",
      cadence_hint: "30m to weekly, depending on research velocity",
      good_for: [
        "cross-domain research", "frontier topic scouting", "finding non-obvious questions",
      ],
      civic_examples: [
        "embodied robotics research salon", "OPC research salon", "EUV lithography research salon",
      ],
    },
    {
      id: "signal-watch",
      title: "Signal Watch",
      category: "long-horizon-monitoring",
      summary: "A watcher checks sources on a real-world cadence, separates no-change cycles from accepted facts, and emits concise change digests.",
      protocol_mode: "observe-filter-update",
      input_contract: "source observation packet",
      reduction_contract: "change/no-change digest",
      output_contract: "civic.signal_watch.digest.v1",
      review_contract: "source quality, novelty, domain relevance, page changes",
      cadence_hint: "15m to daily",
      good_for: ["news monitoring", "policy tracking", "market updates"],
      civic_examples: [
        "OPC watcher", "policy update watch", "local-event signal watch",
      ],
    },
    {
      id: "triage-desk",
      title: "Triage Desk",
      category: "intake-routing",
      summary: "Requests enter one place, get classified, routed, escalated, or closed with an auditable reason.",
      protocol_mode: "intake-classify-route",
      input_contract: "request packet",
      reduction_contract: "routing decision",
      output_contract: "civic.triage.routing.v1",
      review_contract: "priority, owner, risk, missing input",
      cadence_hint: "continuous or operator-triggered",
      good_for: ["operator requests", "bug intake", "citizen service desks"],
      civic_examples: [
        "town operator inbox", "policy help desk", "civic service intake",
      ],
    },
    {
      id: "review-council",
      title: "Review Council",
      category: "quality-governance",
      summary: "Reviewers evaluate an artifact against criteria, produce accept/revise/reject decisions, and return concrete fixes.",
      protocol_mode: "submit-review-decide",
      input_contract: "artifact submission",
      reduction_contract: "review decision",
      output_contract: "civic.review.decision.v1",
      review_contract: "criteria fit, risk, evidence, actionability",
      cadence_hint: "after material artifacts are produced",
      good_for: [
        "research report review", "contest judging", "wiki promotion gates",
      ],
      civic_examples: [
        "research quality council", "innovation contest judges", "resident privacy review",
      ],
    },
    {
      id: "match-market",
      title: "Match Market",
      category: "matching-exchange",
      summary: "Needs, offers, constraints, and trust signals are aggregated, matched, and distributed as introductions or deal rooms.",
      protocol_mode: "aggregate-match-distribute",
      input_contract: "need/offer packet",
      reduction_contract: "match proposal",
      output_contract: "civic.match.proposal.v1",
      review_contract: "fit, consent, conflict, next action",
      cadence_hint: "hourly to weekly",
      good_for: [
        "talent matching", "marketplace offers", "mentor-founder matching",
      ],
      civic_examples: [
        "talent graph", "social matching square", "startup resource market",
      ],
    },
    {
      id: "learning-cohort",
      title: "Learning Cohort",
      category: "education-workflow",
      summary: "Learners, mentors, and content workspaces exchange progress, generate lessons, assign exercises, and review outcomes.",
      protocol_mode: "assess-teach-practice-review",
      input_contract: "learner progress packet",
      reduction_contract: "lesson and exercise plan",
      output_contract: "civic.learning.plan.v1",
      review_contract: "skill gap, exercise quality, measurable outcome",
      cadence_hint: "daily or weekly",
      good_for: ["course generation", "workshop cohorts", "skill ladders"],
      civic_examples: [
        "youth innovation class", "robotics workshop", "AI builder bootcamp",
      ],
    },
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
    },
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
    },
  ]
}

///|
pub fn civic_communication_pattern_for_id(
  id : String,
) -> CivicCommunicationPattern? {
  let key = civic_pattern_key(id)
  for pattern in civic_communication_patterns() {
    if civic_pattern_key(pattern.id) == key {
      return Some(pattern)
    }
  }
  None
}

///|
fn civic_pattern_key(value : String) -> String {
  value.to_lower().trim().to_owned()
}

///|
fn default_research_salon_pattern() -> CivicCommunicationPattern {
  civic_communication_patterns()[0]
}

///|
fn civic_communication_pattern_for_service_kind(
  service_kind : String,
) -> String {
  match service_kind {
    "town-supervision" => "triage-desk"
    "resident-memory" => "review-council"
    "policy-service" => "triage-desk"
    "contest-service" => "review-council"
    "social-matching" => "match-market"
    "talent-graph" => "match-market"
    "vitality-analytics" => "signal-watch"
    "education-service" => "learning-cohort"
    "physical-bridge" => "incident-bridge"
    "market-service" => "match-market"
    "story-service" => "story-forge"
    _ => "triage-desk"
  }
}

///|
pub fn civic_communication_pattern_id_for_service(
  service : @civic.CivicServiceDefinition,
) -> String {
  civic_communication_pattern_for_service_kind(service.service_kind)
}

///|
fn civic_salon_pattern_id(scenario : CivicSalonScenario) -> String {
  match scenario.communication_pattern_id {
    Some(id) => if id.trim().is_empty() { "research-salon" } else { id }
    None => "research-salon"
  }
}

///|
fn civic_salon_pattern_for_scenario(
  scenario : CivicSalonScenario,
) -> CivicCommunicationPattern {
  match civic_communication_pattern_for_id(civic_salon_pattern_id(scenario)) {
    Some(pattern) => pattern
    None => default_research_salon_pattern()
  }
}

///|
fn civic_salon_pattern_label(scenario : CivicSalonScenario) -> String {
  match scenario.communication_pattern_label {
    Some(label) =>
      if label.trim().is_empty() {
        civic_salon_pattern_for_scenario(scenario).title
      } else {
        label
      }
    None => civic_salon_pattern_for_scenario(scenario).title
  }
}

///|
pub fn render_civic_communication_patterns() -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Civic Communication Patterns\n\n")
  builder.write_string("| Pattern | Category | Protocol mode | Good for |\n")
  builder.write_string("| --- | --- | --- | --- |\n")
  for pattern in civic_communication_patterns() {
    builder.write_string(
      "|\{pattern.title}|\{pattern.category}|\{pattern.protocol_mode}|\{pattern.good_for.join(", ")}|\n",
    )
  }
  builder.to_string()
}
