///|
pub fn standing_watch_capability() -> String {
  "standing-watch"
}

///|
pub fn research_evidence_capability() -> String {
  "research-evidence"
}

///|
pub fn pdf_watch_capability() -> String {
  "pdf-watch"
}

///|
pub fn web_tool_surface_capability() -> String {
  "web-tool-surface"
}

///|
pub fn generated_site_capability() -> String {
  "generated-site"
}

///|
pub fn civic_protocol_capability() -> String {
  "civic-protocol"
}

///|
pub fn capability_ids(policy : BookPolicy) -> Array[String] {
  let ids : Array[String] = []
  if has_skill(policy, "standing-watch") &&
    required_file_paths(policy).contains("wiki/history/standing-watch.md") {
    ids.push(standing_watch_capability())
  }
  if has_skill(policy, "standing-watch") &&
    has_skill(policy, "source-diarize") &&
    has_skill(policy, "synthesis-revise") &&
    required_file_paths(policy).contains("wiki/sources/") {
    ids.push(research_evidence_capability())
  }
  if has_skill(policy, "pdf-watch") &&
    has_skill(policy, "pdf-analysis") &&
    required_file_paths(policy).contains("raw/pdf/") {
    ids.push(pdf_watch_capability())
  }
  if output_surface(policy) == "web-tool" &&
    has_skill(policy, "tool-projection") &&
    has_skill(policy, "tool-review") {
    ids.push(web_tool_surface_capability())
  }
  if output_surface(policy) == default_generated_site_surface() {
    ids.push(generated_site_capability())
  }
  if has_skill(policy, "protocol-round") &&
    required_file_paths(policy).contains(
      "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
    ) {
    ids.push(civic_protocol_capability())
  }
  ids
}

///|
pub fn has_capability(policy : BookPolicy, capability_id : String) -> Bool {
  capability_ids(policy).contains(capability_id)
}

///|
pub fn catalog_entry_policy(
  id : String,
  name : String,
  tags : Array[String],
) -> BookPolicy {
  policy_for_type(catalog_entry_type(id, name, tags))
}

///|
pub fn catalog_entry_has_capability(
  id : String,
  name : String,
  tags : Array[String],
  capability_id : String,
) -> Bool {
  has_capability(catalog_entry_policy(id, name, tags), capability_id)
}

///|
pub fn catalog_entry_runs_standing_watch(
  id : String,
  name : String,
  tags : Array[String],
) -> Bool {
  catalog_entry_has_capability(id, name, tags, standing_watch_capability())
}

///|
pub fn catalog_entry_runs_research_evidence(
  id : String,
  name : String,
  tags : Array[String],
) -> Bool {
  catalog_entry_has_capability(id, name, tags, research_evidence_capability())
}

///|
pub fn catalog_entry_runs_civic_protocol(
  id : String,
  name : String,
  tags : Array[String],
) -> Bool {
  catalog_entry_has_capability(id, name, tags, civic_protocol_capability())
}
