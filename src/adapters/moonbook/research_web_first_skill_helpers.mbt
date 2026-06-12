///|
fn web_first_push(lines : Array[String], section : Array[String]) -> Unit {
  for line in section {
    lines.push(line)
  }
}

///|
fn web_first_text(parts : Array[String]) -> String {
  parts.join(" ")
}

///|
fn web_first_minimum_included_sources_text() -> String {
  research_policy_min_included_sources()
}

///|
fn web_first_preferred_included_sources_text() -> String {
  research_policy_preferred_included_source_range()
}

///|
fn web_first_preferred_included_sources_short_text() -> String {
  research_policy_preferred_included_sources()
}

///|
fn web_first_harvest_candidate_fetch_text() -> String {
  research_policy_harvest_candidate_fetch_count()
}

///|
fn web_first_discovery_attempt_limit_text() -> String {
  research_policy_discovery_attempt_limit()
}

///|
fn web_first_core_source_classes() -> String {
  "primary, independent, research-institution, market/adoption, and critique/risk"
}

///|
fn web_first_extended_source_classes() -> String {
  "\{web_first_core_source_classes()}, plus primary-paper/source-data"
}

///|
fn web_first_candidate_source_classes() -> String {
  "primary, independent, research institution, market/adoption, critique/risk, and source-data or paper"
}

///|
fn web_first_front_door_source_classes() -> String {
  "primary/official, customer or adopter, research institution, standards or conference, market/adoption, independent critique, and source-data or paper"
}
