///|
fn research_topic_id(entry : BookCatalogEntry) -> String {
  match @policy.catalog_research_topic_hint(entry.id, entry.name, entry.tags) {
    Some(topic) => topic
    None => normalize_topic_id(entry.id)
  }
}

///|
fn is_external_domain_research_topic(topic : String) -> Bool {
  @research_policy.is_external_domain_topic(topic)
}

///|
fn research_mode_text(topic : String) -> String {
  @research_policy.mode_text(topic)
}

///|
fn research_question_text(topic : String, display : String) -> String {
  @research_policy.question_text(topic, display)
}

///|
fn research_followup_query(topic : String, display : String) -> String {
  @research_policy.followup_query(topic, display)
}

///|
fn research_risk_query(topic : String, display : String) -> String {
  @research_policy.risk_query(topic, display)
}

///|
fn research_web_queries(topic : String) -> Array[String] {
  @research_policy.web_queries(topic)
}

///|
fn research_reference_urls(topic : String) -> Array[String] {
  @research_policy.reference_urls(topic)
}

///|
fn research_local_paths(topic : String) -> Array[String] {
  @research_policy.local_paths(topic)
}
