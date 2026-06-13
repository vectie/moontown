///|
pub fn catalog_entry_archived(tags : Array[String]) -> Bool {
  tags.contains("archived") ||
  tags.contains("hidden") ||
  tags.contains("internal")
}

///|
pub fn catalog_entry_transient(
  id : String,
  name : String,
  purpose : String,
) -> Bool {
  let id = id.to_lower()
  let name = name.to_lower()
  let purpose = purpose.to_lower()
  id.contains("smoke") ||
  name.contains("smoke") ||
  purpose.contains("smoke test") ||
  purpose.contains("smoke-test")
}

///|
pub fn catalog_entry_active(
  id : String,
  name : String,
  purpose : String,
  tags : Array[String],
) -> Bool {
  !catalog_entry_archived(tags) && !catalog_entry_transient(id, name, purpose)
}

///|
pub fn catalog_entry_type(
  id : String,
  name : String,
  tags : Array[String],
) -> String {
  if tags.contains("cookbook") || id.contains("cookbook") {
    return cookbook_type()
  }
  if tags.contains("planbook") || id.has_prefix("plan-") {
    return planbook_type()
  }
  if tags.contains("course") ||
    id.has_prefix("course-") ||
    name.to_lower().contains("course") {
    return course_type()
  }
  if tags.contains("research") ||
    id.has_prefix("research-") ||
    name.to_lower().contains("research") {
    return research_type()
  }
  if tags.contains("civic-service") || id.has_prefix("wenyu-") {
    return civic_type()
  }
  if id == "coding" || id == "finance" || tags.contains("operational") {
    return operational_type()
  }
  general_type()
}
