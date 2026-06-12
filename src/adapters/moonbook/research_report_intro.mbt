///|
fn research_report_skill_frontmatter() -> String {
  [
    "---", "name: research-report", "description: Turn screened research artifacts into a long-form, reader-facing deep research report with evidence-backed claims, comparison tables, diagrams, and explicit limits.",
    "---",
  ].join("\n")
}

///|
fn research_report_skill_intro(display : String) -> String {
  [
    "",
    "# Research Report Skill For \{display}",
    "",
    "Use this skill after source collection and evidence extraction. It is not a source-fetching skill; if evidence is missing, write blockers and limits instead of inventing claims.",
  ].join("\n")
}

///|
fn research_report_temperament_section() -> String {
  [
    "", "## Research Temperament", "", "Correctness is necessary but not sufficient.",
    "", "- Imagination: propose mechanisms, futures, substitutions, hidden constraints, and second-order consequences; then test them against evidence.",
    "- Curiosity: ask why the topic matters now, what changed recently, what would surprise a serious reader, and which missing fact would change the conclusion.",
    "- Judgement: rank evidence quality, reject weak sources, distinguish signal from hype, and decide what deserves durable memory.",
    "- Taste: write with a point of view. The report should help a human make sense of the topic, not merely prove that a pipeline ran.",
  ].join("\n")
}
