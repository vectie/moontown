///|
pub struct PolicySpec {
  profile : @policy.PolicyProfile
  repair_action : String
} derive(Debug, Eq)

///|
fn policy_spec(
  profile : @policy.PolicyProfile,
  repair_action : String,
) -> PolicySpec {
  { profile, repair_action }
}

///|
fn policy_profile_spec(
  profile : @policy.PolicyProfile,
  repair_action : String,
) -> PolicySpec {
  policy_spec(profile, repair_action)
}

///|
fn policy_specs() -> Array[PolicySpec] {
  [
    policy_profile_spec(
      @policy.policy_profile_for_type(@policy.research_type()).unwrap(),
      research_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(@policy.course_type()).unwrap(),
      course_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(@policy.planbook_type()).unwrap(),
      planbook_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(@policy.cookbook_type()).unwrap(),
      cookbook_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(@policy.civic_type()).unwrap(),
      civic_repair_action(),
    ),
    policy_profile_spec(
      @policy.policy_profile_for_type(@policy.operational_type()).unwrap(),
      operational_repair_action(),
    ),
  ]
}

///|
pub fn policy_spec_for_type(book_type : String) -> PolicySpec? {
  for spec in policy_specs() {
    if spec.profile.book_type == book_type {
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
