///|
fn civic_salon_skill_text(scenario : CivicSalonScenario) -> String {
  let pattern = civic_salon_pattern_for_scenario(scenario)
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
