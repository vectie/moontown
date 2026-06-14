///|
fn research_request_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let external_domain = is_external_domain_research_topic(topic)
  [
    "# Research Request",
    "",
    "- Topic: \{display}",
    "- Goal: produce a researcher-grade dossier and durable wiki coverage that is specific to \{display}, not generic scaffold text.",
    "- Mode: \{research_mode_text(topic)}",
    "- Research question: \{research_question_text(topic, display)}",
    @research_policy.request_quality_bar_bullet(),
    @research_policy.request_depth_target_bullet(),
    @research_policy.request_reference_style_bullet(display),
    "- Required MoonClaw worker outputs:",
    research_raw_output_bullets(),
    "- Required MoonBook materialization outputs after raw evidence is ready:",
    research_materialization_output_bullets(),
    "",
    "## Execution Order",
    "",
    research_execution_order(external_domain).join("\n"),
    "",
    "## Blocking Rule",
    "",
    research_blocking_rules().join("\n"),
  ].join("\n")
}
