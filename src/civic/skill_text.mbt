///|
pub fn service_skill_path(
  root : String,
  service : CivicServiceDefinition,
) -> String {
  "\{root}/\{service.skill_path}"
}

///|
pub fn wenyu_civic_service_skill_text() -> String {
  [
    civic_skill_frontmatter(
      "wenyu-civic-service", "Operate one Wenyu Valley civic module as a MoonBook-backed service with review gates and projection-safe output.",
    ),
    "# Wenyu Civic Service Skill",
    "",
    "Use this generic skill with the module-specific skill pack in the same workspace.",
    civic_generic_service_rules_section(),
    @skill_quality.exploration_quality_contract_section(),
    civic_required_output_shape_section(),
    civic_generic_service_example_section(),
  ].join("\n")
}

///|
pub fn civic_module_skill_text(service : CivicServiceDefinition) -> String {
  [
    civic_skill_frontmatter(
      service.skill_pack,
      "Role-specific MoonClaw skill pack for Wenyu Valley \{service.title}.",
    ),
    "",
    "# \{service.title} Skill Pack",
    "",
    "You are operating the `\{service.title}` module for Wenyu Valley.",
    civic_module_mode_section(service),
    civic_module_purpose_section(service),
    civic_module_decision_section(),
    @skill_quality.exploration_quality_contract_section(),
    civic_module_work_section("Agent Work", service.agent_work),
    civic_module_work_section("Place / Exchange Work", service.place_work),
    civic_module_work_section("Workflow Hints", service.workflow),
    civic_module_output_contract_section(service),
    civic_module_mode_output_section(service),
    civic_module_work_section("Durable Pages", service.target_pages),
    civic_module_work_section("Acceptance", service.acceptance),
    "## Concrete Example\n",
    civic_skill_example(service),
  ].join("\n")
}

///|
pub fn communication_participant_skill_text(
  scenario : CivicCommunicationScenario,
) -> String {
  let pattern = communication_pattern_for_scenario(scenario)
  [
    "---",
    "name: \{scenario.skill_name}",
    "description: \{scenario.skill_description}",
    "---",
    "",
    "# \{scenario.title} Skill",
    "",
    "This skill is for an internal participant workspace entering the `\{pattern.title}` communication pattern inside a shared building protocol.",
    "",
    "Pattern summary: \{pattern.summary}",
    "",
    "## Behavior",
    "",
    markdown_bullets(scenario.skill_rules),
    "",
    @skill_quality.exploration_quality_contract_section(),
    "",
    "## Output Example",
    "",
    "```md",
    "pattern_decision: update",
    "participant_focus: policy-source-review",
    "bottleneck: resident intake lacks required eligibility facts",
    "cross_area_dependency: official source selection and review gate",
    "follow_up_question: Which missing input should be requested before a checklist is safe?",
    "next_artifact: wiki/queries/policy-questions.md",
    "```",
  ].join("\n")
}

///|
pub fn communication_reducer_skill_text(
  scenario : CivicCommunicationScenario,
) -> String {
  let pattern = communication_pattern_for_scenario(scenario)
  [
    "---",
    "name: \{scenario.skill_name}",
    "description: \{scenario.skill_description}",
    "---",
    "",
    "# \{scenario.title} Reducer Skill",
    "",
    civic_salon_reducer_role_description(pattern),
    "",
    "Pattern summary: \{pattern.summary}",
    "",
    "## Required Behavior",
    "",
    markdown_bullets(scenario.skill_rules),
    "",
    "## Quality Rules",
    "",
    markdown_bullets(scenario.quality_rules),
    "",
    @skill_quality.exploration_quality_contract_section(),
    "",
    "## Reduction Rules",
    "",
    markdown_bullets(civic_salon_reducer_reduction_rules()),
    "",
    "## Output Contract",
    "",
    civic_salon_reducer_output_contract_summary(),
    "",
    "Write `\{civic_reducer_output_relative_path()}` exactly as JSON:",
    "",
    civic_salon_reducer_output_contract_json_example(),
    "",
    "## Concrete Example",
    "",
    civic_salon_reducer_concrete_examples(),
  ].join("\n")
}

///|
pub fn communication_reducer_input_markdown(
  scenario : CivicCommunicationScenario,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern = communication_pattern_for_scenario(scenario)
  [
    "# Civic Communication Pattern Reducer Input",
    "",
    "- Scenario: \{scenario.title}",
    "- Communication pattern: \{pattern.title} (`\{pattern.id}`)",
    "- Domain: \{scenario.domain_label}",
    "- Topic: \{scenario.topic}",
    "- Building: `\{scenario.building_id}`",
    "- Round: `\{round_id}` (#\{round_number})",
    "- Protocol channel: `\{scenario.protocol_channel}`",
    "- Output channel: `\{scenario.output_channel}`",
    "- Review gate: `\{scenario.review_gate}`",
    "",
    "The only authoritative inputs for reduction are the participant records and the generated skill/contract files. Template fixture ideas are intentionally not present in this reducer workspace.",
  ].join("\n")
}

///|
pub fn communication_reducer_contract_markdown(
  scenario : CivicCommunicationScenario,
) -> String {
  [
    "# Civic Communication Pattern Output Contract",
    "",
    "Emit a non-empty set of `\{civic_reducer_output_contract_type_name()}` records to `\{civic_reducer_output_relative_path()}`. The record is the generic civic communication output shape while the runtime continues to migrate away from salon-specific names.",
    "",
    "Each idea must include:",
    "",
    "- `id`: stable lowercase id",
    "- `title`: human-readable idea title",
    "- `summary`: cross-area dependency, routing decision, match proposal, lesson plan, story angle, or recovery action",
    "- `participating_books`: participant workspace ids from the input JSON",
    "- `research_questions`: at least one testable follow-up or review question",
    "- `why_it_matters`: judgement about why the output is worth tracking",
    "- `next_experiment`: smallest useful next experiment, action, artifact, drill, or review exercise",
    "",
    "The reducer must not create accepted facts. It creates reviewable directions or service outputs that are distributed back to internal participant workspaces through `\{scenario.output_channel}` and reviewed by `\{scenario.review_gate}`.",
  ].join("\n")
}

///|
fn civic_skill_frontmatter(name : String, description : String) -> String {
  ["---", "name: \{name}", "description: \{description}", "---"].join("\n")
}

///|
fn civic_skill_section(title : String, body : String) -> String {
  "\n## \{title}\n\n\{body}"
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("- ")
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string().trim().to_owned()
}

///|
fn civic_generic_service_rules_section() -> String {
  civic_skill_section("Rules", civic_generic_service_rules().join("\n"))
}

///|
fn civic_generic_service_rules() -> Array[String] {
  [
    "- Read `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md` and `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md` before acting.",
    "- First identify the module mode: agent-workspace, exchange-place, projection-surface, gateway, or hybrid.",
    "- Then identify the persistence mode: workspace-backed, ledger-backed, projection-backed, handoff-ledger-backed, or mixed-memory-backed.",
    "- Do not force every civic module into research. Use research only when the module-specific skill asks for source discovery or evidence verification.",
    "- Choose the next useful service action from current book state, place state, and review gates; do not follow a fixed script.",
    "- For exchange-place modules, produce consent, ledger, match, request, or follow-up records rather than long reports.",
    "- For projection-surface modules, produce status, freshness, anomaly, and recovery records rather than domain research.",
    "- For gateway modules, produce confirmation-gated handoff packets and blockers; never imply external execution happened without approval.",
    "- For agent-workspace modules, produce the domain-specific artifact named by the dedicated skill pack.",
    "- Treat the building as a protocol place: map inputs into contributions, group compatible contributions, reduce them into a module-native output, and distribute only through allowed channels.",
    "- Use source evidence for knowledge claims and record source gaps clearly when knowledge claims are part of the module work.",
    "- Persist durable results to the MoonBook role defined in the contract and projection summaries to `book/moonbook-ui-state.json` only through review-safe records.",
    "- If the persistence mode is ledger-backed or projection-backed, prefer compact records and summaries over wiki essays.",
    "- Queue review for public, legal, financial, personal, booking, robot, or offline-impact actions.",
    "- Separate operational activity from domain progress.",
  ]
}

///|
fn civic_required_output_shape_section() -> String {
  civic_skill_section(
    "Required Output Shape",
    [
      "Return Markdown with these fields:",
      "",
      "- `civic_service_decision: update | no_change | needs_review | blocked`",
      "- `book_changed: yes | no`",
      "- `wiki_pages_changed_count: <integer>`",
      "- `changed_pages: comma-separated durable page paths, or none`",
      "- `accepted_facts_count: <integer>`",
      "- `review_items_created_count: <integer>`",
      "- `review_items: comma-separated review item ids/paths, or none`",
      "- `projection_updated: yes | no`",
      "- `projection_delta: one sentence explaining the projection-safe change, or blocked:<reason>`",
      "- `protocol_decision_basis: one sentence naming the evidence, ledger, or blocker basis for the decision`",
      "- `next_check_hint: normal | faster | slower | review`",
      "",
      civic_accepted_facts_accounting_rule(),
    ].join("\n"),
  )
}

///|
fn civic_accepted_facts_accounting_rule() -> String {
  "`accepted_facts_count` means accepted domain/service records for the module. For exchange-place, gateway, projection-surface, and hybrid modules, do not treat generic operational retries or daemon logs as accepted facts."
}

///|
fn civic_generic_service_example_section() -> String {
  civic_skill_section(
    "Concrete Example",
    [
      "```md", "civic_service_decision: needs_review", "book_changed: yes", "wiki_pages_changed_count: 2",
      "changed_pages: wiki/sources/policies.md, wiki/queries/policy-questions.md",
      "accepted_facts_count: 3", "review_items_created_count: 1", "review_items: wiki/reviews/policy-citations.md#deadline-uncertainty",
      "projection_updated: yes", "projection_delta: Added a review-safe eligibility checklist summary to the generated policy view.",
      "protocol_decision_basis: Official source metadata was accepted, but the deadline interpretation needs keeper review.",
      "next_check_hint: review", "", "Summary: Policy Hall found a new official eligibility notice, updated the checklist, and queued an uncertain deadline interpretation for keeper review.",
      "Artifacts: `wiki/sources/policies.md`, `wiki/queries/policy-questions.md`, `wiki/reviews/policy-citations.md`",
      "```",
    ].join("\n"),
  )
}

///|
fn civic_module_mode_section(service : CivicServiceDefinition) -> String {
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
fn civic_module_purpose_section(service : CivicServiceDefinition) -> String {
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
  service : CivicServiceDefinition,
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
fn civic_module_mode_output_section(service : CivicServiceDefinition) -> String {
  civic_skill_section(
    "Mode-Specific Output",
    civic_mode_output_guidance(service),
  )
}

///|
fn civic_mode_output_guidance(service : CivicServiceDefinition) -> String {
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

///|
fn civic_skill_example(service : CivicServiceDefinition) -> String {
  let first_page = service.wiki_pages.get(0).unwrap_or("wiki/civic/module.md")
  let review_page = service.review_queues
    .get(0)
    .unwrap_or("wiki/reviews/module.md")
  [
    "```md",
    "civic_service_decision: update",
    "book_changed: yes",
    "wiki_pages_changed_count: 2",
    "accepted_facts_count: 4",
    "review_items_created_count: 1",
    "projection_updated: yes",
    "next_check_hint: normal",
    "",
    civic_skill_example_summary(service, first_page, review_page),
    "",
    "Evidence and judgment:",
    "- What changed: one concrete service fact, exchange record, gateway request, projection state, or operating condition.",
    "- Why it matters: resident/operator impact.",
    "- What remains uncertain: source, policy, consent, budget, privacy, or offline-action risk.",
    "",
    "Artifacts:",
    "- `\{first_page}`",
    "- `\{review_page}`",
    "- `book/moonbook-ui-state.json`",
    "```",
  ].join("\n")
}

///|
fn civic_skill_example_summary(
  service : CivicServiceDefinition,
  first_page : String,
  review_page : String,
) -> String {
  [
    "Summary: \{service.title} followed `\{service.module_mode}` / `\{service.skill_mode}` mode,",
    "selected the most useful module-native action from current book and place state,",
    "updated `\{first_page}`,",
    "and queued one review item in `\{review_page}` because the action affects public/user-facing service behavior.",
  ].join(" ")
}

///|
fn civic_salon_reducer_role_description(
  pattern : CivicCommunicationPattern,
) -> String {
  [
    "This skill controls the building-level reducer for the `\{pattern.title}` communication pattern.",
    "The reducer is an agentic map-reduce place: internal participant workspaces map perspectives, requests, constraints, signals, or artifacts into packets, then this worker reduces them into useful reviewable outputs for return-home work.",
  ].join(" ")
}

///|
fn civic_salon_reducer_reduction_rules() -> Array[String] {
  [
    "Read every participant in `\{civic_reducer_participants_relative_path()}`.",
    "Use at least two participant workspaces for each idea unless the participant set itself has only one workspace.",
    "Generate outputs from tensions, dependencies, missing interfaces, evaluation gaps, shared bottlenecks, matching opportunities, routing needs, or safety gates.",
    "Prefer follow-up questions that can become benchmarks, protocols, schemas, experiments, service actions, matched introductions, lesson plans, stories, recovery steps, or review gates.",
    "Do not claim the output is accepted knowledge. It is a returned direction for the owning books and review gate.",
    "Do not copy or consume template seed ideas. If seed examples exist elsewhere, ignore them.",
    "Every output must name the home books that should receive the returned idea, question, match, lesson, story, or service action.",
    "Every output must include a next action small enough for one bookkeeper or one bounded worker packet.",
    "Prefer outputs that create useful tension between participants rather than averaging them into generic consensus.",
    "If no substantive exchange is possible, emit a blocker-style output with the missing participant context and review gate instead of hallucinating civic progress.",
  ]
}

///|
fn civic_salon_reducer_output_contract_summary() -> String {
  [
    "Emit the same `CivicCommunicationIdea` contract that Moontown materializes into building ledgers, internal participant workspaces, review queues, and projections.",
    "For non-research patterns, treat `research_questions` as testable follow-up or review questions and `next_experiment` as the smallest useful next artifact/action.",
  ].join(" ")
}

///|
fn civic_salon_reducer_output_contract_json_example() -> String {
  [
    "```json", "{", "  \"ideas\": [", "    {", "      \"id\": \"lowercase-stable-id\",",
    "      \"title\": \"Short pattern output title\",", "      \"summary\": \"One or two precise sentences explaining the cross-area dependency, routing decision, match, lesson plan, story angle, or recovery action.\",",
    "      \"participating_books\": [\"workspace-a\", \"workspace-b\"],", "      \"research_questions\": [",
    "        \"A testable question that belongs in follow-up work\",", "        \"A second question that forces a concrete experiment or review gate\"",
    "      ],", "      \"why_it_matters\": \"Why this could change the domain program or civic service outcome.\",",
    "      \"next_experiment\": \"The smallest useful next experiment, prototype, benchmark, schema, service action, story draft, match review, lesson exercise, or recovery drill.\"",
    "    }", "  ],", "  \"summary\": \"Reducer-level summary.\"", "}", "```",
  ].join("\n")
}

///|
fn civic_salon_reducer_concrete_examples() -> String {
  [
    civic_salon_reducer_good_research_example(),
    civic_salon_reducer_good_service_example(),
    civic_salon_reducer_poor_output_example(),
  ].join(" ")
}

///|
fn civic_salon_reducer_good_research_example() -> String {
  "For a robotics research salon with VLA, world-model, manipulation, and safety workspaces, a good idea links perception-action policy limits to world-model uncertainty and proposes a concrete benchmark."
}

///|
fn civic_salon_reducer_good_service_example() -> String {
  "For a policy triage desk, a good output routes a resident question to official-source extraction plus review instead of inventing eligibility advice."
}

///|
fn civic_salon_reducer_poor_output_example() -> String {
  "A poor output merely says \"combine sources\" or \"help the resident\" without owner workspaces, a checkable follow-up question, or a review gate."
}
