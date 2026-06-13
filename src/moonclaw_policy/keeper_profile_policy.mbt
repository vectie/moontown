///|
pub fn planbook_keeper_profile() -> String {
  "planbook_repair_worker"
}

///|
pub fn civic_keeper_profile() -> String {
  "wenyu_civic_service_worker"
}

///|
pub fn keeper_profile_override_for_book_type(book_type : String) -> String? {
  if book_type == @policy.planbook_type() {
    return Some(planbook_keeper_profile())
  }
  if book_type == @policy.civic_type() {
    return Some(civic_keeper_profile())
  }
  None
}

///|
pub fn keeper_profile_override_for_catalog_entry(
  id : String,
  name : String,
  tags : Array[String],
) -> String? {
  keeper_profile_override_for_book_type(
    @policy.catalog_entry_type(id, name, tags),
  )
}
