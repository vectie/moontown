///|
fn web_first_research_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let sample_query = research_web_queries(topic).get(0).unwrap_or(display)
  let sample_url = research_reference_urls(topic)
    .get(0)
    .unwrap_or("source chosen from screened web discovery")
  let lines : Array[String] = []
  web_first_push(lines, web_first_header_section())
  web_first_push(lines, web_first_temperament_section())
  web_first_push(lines, web_first_reference_style_section(display))
  web_first_push(lines, web_first_method_section())
  web_first_push(lines, web_first_rules_section(topic))
  web_first_push(lines, web_first_required_output_section(display))
  web_first_push(lines, web_first_deep_dossier_section())
  web_first_push(lines, web_first_search_result_fallback_section())
  web_first_push(lines, web_first_front_door_fallback_section())
  web_first_push(
    lines,
    web_first_example_workflow_section(topic, display, sample_query, sample_url),
  )
  web_first_push(lines, web_first_output_contract_example_section())
  lines.join("\n")
}
