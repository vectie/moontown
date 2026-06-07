///|
fn civic_module_mode_section(service : @civic.CivicServiceDefinition) -> String {
  civic_skill_section(
    "Mode",
    [
      "- Module mode: `\{service.module_mode}`",
      "- Persistence mode: `\{service.persistence_mode}`",
      "- MoonBook role: `\{service.book_role}`",
      "- Skill mode: `\{service.skill_mode}`",
    ].join("\n"),
  )
}

///|
fn civic_module_purpose_section(
  service : @civic.CivicServiceDefinition,
) -> String {
  civic_skill_section("Purpose", service.purpose)
}

///|
fn civic_module_decision_section() -> String {
  civic_skill_section(
    "What To Decide",
    [
      "- Inspect the current MoonBook support workspace and decide whether the next service action is an update, no-change digest, review queue, or blocker.",
      "- Treat the MoonBook as supporting memory, not necessarily the product surface or the civic place.",
      "- Prefer the highest-value action for a real civic operator and resident, not a generic wiki maintenance step.",
      "- Do not produce a generic research report unless this module's skill mode explicitly requires source research.",
      "- Use imagination, curiosity, and judgment: ask what would genuinely help the resident, operator, or town ecosystem, then constrain the answer by evidence and safety.",
    ].join("\n"),
  )
}

///|
fn civic_module_work_section(title : String, bullets : Array[String]) -> String {
  civic_skill_section(title, markdown_bullets(bullets))
}

///|
fn civic_module_output_contract_section(
  service : @civic.CivicServiceDefinition,
) -> String {
  civic_skill_section(
    "Output Contract",
    [
      "- Contract id: `\{service.output_contract}`",
      "- Must include changed pages, basis for the decision, review items, projection delta, and next check hint.",
      "- Count accepted facts only when they are accepted domain/service records for this module; do not count daemon retries, process logs, or generic activity.",
      "- Must not claim external action completion unless a reviewed external action actually happened.",
      "- Must respect `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`: allowed inputs, outputs, review gates, privacy scope, and distribution policy.",
    ].join("\n"),
  )
}

///|
fn civic_module_mode_output_section(
  service : @civic.CivicServiceDefinition,
) -> String {
  civic_skill_section(
    "Mode-Specific Output",
    civic_mode_output_guidance(service),
  )
}

///|
fn civic_mode_output_guidance(
  service : @civic.CivicServiceDefinition,
) -> String {
  match service.module_mode {
    "agent-workspace" =>
      "- Produce the domain artifact named by `\{service.skill_mode}`. Use research only if the artifact requires source discovery or evidence verification."
    "exchange-place" =>
      "- Produce consent, match, request, event, ledger, or follow-up records. Keep the output short, action-oriented, and review-gated instead of report-shaped."
    "projection-surface" =>
      "- Produce status, freshness, anomaly, recovery, and accounting records. Separate what changed from what merely ran."
    "gateway" =>
      "- Produce handoff packets, required confirmations, blockers, and next offline owner. Never state that offline action happened unless confirmed."
    "hybrid" =>
      "- Produce the smallest useful mix of workspace artifact and place-facing projection. Explicitly separate private memory, public projection, and review items."
    _ =>
      "- Produce the module-native artifact described by the skill mode; do not default to generic research."
  }
}
