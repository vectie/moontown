///|
fn research_wiki_ingest_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let lines : Array[String] = []
  research_ingest_push(lines, research_ingest_header_section(display))
  if is_external_domain_research_topic(topic) {
    research_ingest_push(lines, research_ingest_domain_guard_section(display))
  }
  research_ingest_push(lines, research_ingest_mandatory_method_section())
  research_ingest_push(lines, research_ingest_required_raw_files_section())
  research_ingest_push(
    lines,
    research_ingest_required_wiki_files_section(topic, display),
  )
  research_ingest_push(lines, research_ingest_verified_source_page_section())
  research_ingest_push(lines, research_ingest_example_result_section(display))
  lines.push(
    "If you cannot create the required files, return a blocker result. Do not mark the task complete with only generic source pages.",
  )
  lines.join("\n")
}
