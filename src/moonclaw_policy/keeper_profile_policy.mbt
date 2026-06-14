///|
pub fn planbook_keeper_profile() -> String {
  "planbook_repair_worker"
}

///|
pub fn civic_keeper_profile() -> String {
  "wenyu_civic_service_worker"
}

///|
pub fn keeper_profile_override_for_policy(
  policy : @policy.BookPolicy,
) -> String? {
  if @policy.has_skill(policy, "code-plan") &&
    @policy.has_skill(policy, "repair-dispatch") {
    return Some(planbook_keeper_profile())
  }
  if @policy.has_capability(policy, @policy.civic_protocol_capability()) {
    return Some(civic_keeper_profile())
  }
  None
}

///|
pub fn keeper_profile_override_for_book_type(book_type : String) -> String? {
  keeper_profile_override_for_policy(@policy.policy_for_type(book_type))
}

///|
pub fn keeper_profile_override_for_catalog_entry(
  id : String,
  name : String,
  tags : Array[String],
) -> String? {
  keeper_profile_override_for_policy(
    @policy.catalog_entry_policy(id, name, tags),
  )
}
