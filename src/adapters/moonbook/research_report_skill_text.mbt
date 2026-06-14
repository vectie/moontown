///|
fn research_report_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    research_report_skill_frontmatter(),
    research_report_skill_intro(display),
    @research_policy.report_non_negotiable_output_section(display),
    research_report_reference_output_rule_section(display),
    @research_policy.report_no_reference_rule_section(),
    research_report_temperament_section(),
    @research_policy.report_required_inputs_section(),
    @research_policy.report_article_shape_section(),
    @research_policy.report_quality_rubric_section(),
    research_report_concrete_example_section(display),
    research_report_final_revision_rule(topic),
  ].join("\n")
}
