///|
fn civic_salon_reducer_skill_text(scenario : CivicSalonScenario) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
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
    "## Reduction Rules",
    "",
    markdown_bullets(civic_salon_reducer_reduction_rules()),
    "",
    "## Output Contract",
    "",
    civic_salon_reducer_output_contract_summary(),
    "",
    "Write `raw/bootstrap/civic-salon-ideas.json` exactly as JSON:",
    "",
    civic_salon_reducer_output_contract_json_example(),
    "",
    "## Concrete Example",
    "",
    civic_salon_reducer_concrete_examples(),
  ].join("\n")
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
    "Read every participant in `raw/bootstrap/civic-salon-participants.json`.", "Use at least two participant workspaces for each idea unless the participant set itself has only one workspace.",
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
    "Emit the same `CivicSalonIdea` contract that Moontown materializes into building ledgers, internal participant workspaces, review queues, and projections.",
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

///|
fn civic_salon_reducer_input_markdown(
  scenario : CivicSalonScenario,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
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
fn civic_salon_reducer_contract_markdown(
  scenario : CivicSalonScenario,
) -> String {
  [
    "# Civic Communication Pattern Output Contract",
    "",
    "Emit a non-empty set of `CivicSalonIdea` records to `raw/bootstrap/civic-salon-ideas.json`. The legacy type name is reused for every civic communication pattern while the runtime is experimental.",
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
