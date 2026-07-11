///|
pub fn operating_architecture_markdown() -> String {
  planbook_markdown_page(
    [
      "# Operating Architecture", "", "This page is the PlanBook-local contract for keeping MoonTown coherent while it runs and changes itself.",
      "",
    ],
    [
      planbook_core_doctrine_section(),
      planbook_runtime_spine_section(),
      planbook_growth_contract_section(),
      planbook_stable_watch_state_section(),
      planbook_civic_wiring_rule_section(),
      planbook_future_code_rule_section(),
    ],
  )
}

///|
fn planbook_core_doctrine_section() -> Array[String] {
  [
    "## Core Doctrine", "", "- Durable state lives in MoonBook documents, ledgers, schemas, plans, reviews, and generated projections.",
    "- Active behavior is a protocol over those documents.", "- Buildings are protocol places: they accept packets, aggregate context, coordinate exchange, reduce outputs, run review gates, and distribute results home.",
    "- MoonClaw workers are temporary freelance executors. They do bounded tool-heavy work and return structured output.",
    "- Bookkeepers are resident MoonBook roles. They wake on schedules/events to decide what becomes memory and what needs review.",
    "- The Mayor owns town-wide cadence, routing, health, escalation, and cross-book priority.",
    "- Every registered book owns a watcher lane so standing goals can always be routed to the target book before any domain-specific worker is required.",
    "",
  ]
}

///|
fn planbook_runtime_spine_section() -> Array[String] {
  [
    "## Runtime Spine", "", "```text", "operator goal / standing goal / civic schedule / planbook gap",
    "  -> Mayor routes and schedules", "  -> target MoonBook or building protocol hydrates durable context",
    "  -> MoonClaw worker executes one bounded packet", "  -> MoonBook bookkeeper reviews memory, wiki, ledgers, projections",
    "  -> MoonTown records town-level ledger, health, visual state, and next action",
    "```", "",
  ]
}

///|
fn planbook_growth_contract_section() -> Array[String] {
  let lines : Array[String] = [
    "## Growth Contract", "", "The town is considered alive only when at least one of these changes over time:",
    "",
  ]
  for signal in planbook_growth_signals() {
    lines.push(signal)
  }
  for line in ["", planbook_operational_activity_accounting_rule(), ""] {
    lines.push(line)
  }
  lines
}

///|
fn planbook_growth_signals() -> Array[String] {
  [
    "- research/course/plan/cookbook/civic books gain accepted pages, review items, or explicit no-change decisions",
    "- civic protocol ledgers gain inbox, contribution, reduction, outbox, review, or return-home records",
    "- PlanBook backlog items become plans, patches, validation evidence, or blockers",
    "- code changes land through the PlanBook repair loop with tests, diff hygiene, and commit readiness",
    "- UI projections refresh from runtime state rather than hand-authored demo text",
  ]
}

///|
fn planbook_operational_activity_accounting_rule() -> String {
  [
    "Operational activity alone is not growth.", "Retries, regenerated sites, no-change ticks, and logs must be accounted",
    "separately from domain knowledge or implementation progress.",
  ].join(" ")
}

///|
fn planbook_stable_watch_state_section() -> Array[String] {
  [
    "## Stable Watch State",
    "",
    planbook_stable_watch_state_rule(),
    "",
    planbook_review_gated_artifact_rule(),
    "",
  ]
}

///|
fn planbook_stable_watch_state_rule() -> String {
  [
    "The desired mature state is healthy watching, not permanent motion:", "daemon healthy, active workers zero, unresolved failures zero,",
    "PlanBook open gaps zero, due standing goals zero, civic schedules enabled",
    "for the next interval, and review queues visible without being counted as",
    "accepted progress.",
  ].join(" ")
}

///|
fn planbook_review_gated_artifact_rule() -> String {
  [
    "Routine review-gated artifacts do not block the live loop by themselves.", "They stay visible for bookkeeper/operator/AI-review judgment while the",
    "Mayor continues scheduled watches and civic protocol rounds.",
  ].join(" ")
}

///|
fn planbook_civic_wiring_rule_section() -> Array[String] {
  ["## Civic Wiring Rule", "", planbook_civic_wiring_rule(), ""]
}

///|
fn planbook_civic_wiring_rule() -> String {
  [
    "Every civic building must have a document protocol pack with an inbox,", "ledger, reducer contract, review gate, distribution policy, and",
    "return-home rule. New ideas are not complete until they are sent back to", "the owning MoonBook or explicitly parked in a review queue.",
  ].join(" ")
}

///|
fn planbook_future_code_rule_section() -> Array[String] {
  ["## PlanBook Rule", "", planbook_future_code_rule()]
}

///|
fn planbook_future_code_rule() -> String {
  [
    "Future code work should come from a PlanBook plan or backlog item.", "If the daemon finds that the requested work is already done, it updates",
    "the plan/backlog/progress evidence instead of creating code churn.",
  ].join(" ")
}
