///|
pub struct PolicySpec {
  book_type : String
  repair_action : String
  source_policy : String
  policy : @policy.BookPolicy
} derive(Debug, Eq)

///|
fn policy_spec(
  book_type : String,
  repair_action : String,
  source_policy : String,
  policy : @policy.BookPolicy,
) -> PolicySpec {
  { book_type, repair_action, source_policy, policy }
}

///|
fn policy_profile_spec(
  profile : @policy.PolicyProfile,
  repair_action : String,
) -> PolicySpec {
  policy_spec(
    profile.book_type,
    repair_action,
    profile.source_policy,
    profile.policy,
  )
}

///|
fn policy_specs() -> Array[PolicySpec] {
  [
    policy_profile_spec(
      @policy.policy_profile_for_type(research_type()).unwrap(),
      research_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(course_type()).unwrap(),
      course_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(planbook_type()).unwrap(),
      planbook_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(cookbook_type()).unwrap(),
      cookbook_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(civic_type()).unwrap(),
      civic_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(operational_type()).unwrap(),
      operational_repair_action(),
    ),
  ]
}

///|
pub fn policy_spec_for_type(book_type : String) -> PolicySpec? {
  for spec in policy_specs() {
    if spec.book_type == book_type {
      return Some(spec)
    }
  }
  None
}

///|
pub fn source_policy_for_type(book_type : String) -> String {
  @policy.source_policy_for_type(book_type)
}

///|
pub fn policy_for_type(book_type : String) -> @policy.BookPolicy {
  @policy.policy_for_type(book_type)
}

///|
pub fn repair_action_for_type(book_type : String) -> String {
  match policy_spec_for_type(book_type) {
    Some(spec) => spec.repair_action
    None => general_repair_action()
  }
}
