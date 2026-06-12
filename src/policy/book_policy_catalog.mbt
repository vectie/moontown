///|
pub fn research_type() -> String {
  "research-book"
}

///|
pub fn course_type() -> String {
  "course-book"
}

///|
pub fn planbook_type() -> String {
  "planbook"
}

///|
pub fn cookbook_type() -> String {
  "cookbook"
}

///|
pub fn civic_type() -> String {
  "civic-protocol-support"
}

///|
pub fn operational_type() -> String {
  "operational-book"
}

///|
pub fn general_type() -> String {
  "general-book"
}

///|
pub fn reviewable_types() -> Array[String] {
  [
    research_type(),
    course_type(),
    planbook_type(),
    cookbook_type(),
    civic_type(),
    operational_type(),
  ]
}

///|
pub fn web_first_policy() -> String {
  "web-first"
}

///|
pub fn book_first_policy() -> String {
  "book-first"
}

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
