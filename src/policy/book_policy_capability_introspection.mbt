///|
pub fn capability_ids(policy : BookPolicy) -> Array[String] {
  let ids : Array[String] = []
  if has_skill(policy, "standing-watch") &&
    required_file_paths(policy).contains("wiki/history/standing-watch.md") {
    ids.push("standing-watch")
  }
  if has_skill(policy, "pdf-watch") &&
    has_skill(policy, "pdf-analysis") &&
    required_file_paths(policy).contains("raw/pdf/") {
    ids.push("pdf-watch")
  }
  if output_surface(policy) == "web-tool" &&
    has_skill(policy, "tool-projection") &&
    has_skill(policy, "tool-review") {
    ids.push("web-tool-surface")
  }
  if output_surface(policy) == default_generated_site_surface() {
    ids.push("generated-site")
  }
  ids
}

///|
pub fn has_capability(policy : BookPolicy, capability_id : String) -> Bool {
  capability_ids(policy).contains(capability_id)
}
