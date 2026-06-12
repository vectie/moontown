///|
pub struct PolicyProfile {
  book_type : String
  source_policy : String
  policy : BookPolicy
} derive(Debug, Eq)

///|
fn profile(
  book_type : String,
  source_policy : String,
  policy : BookPolicy,
) -> PolicyProfile {
  { book_type, source_policy, policy }
}

///|
fn book_first_profile(book_type : String, policy : BookPolicy) -> PolicyProfile {
  profile(book_type, book_first_policy(), policy)
}

///|
pub fn policy_profiles() -> Array[PolicyProfile] {
  [
    profile(research_type(), web_first_policy(), research()),
    book_first_profile(course_type(), course()),
    book_first_profile(planbook_type(), planbook()),
    book_first_profile(cookbook_type(), cookbook()),
    book_first_profile(civic_type(), civic_protocol()),
    book_first_profile(operational_type(), operational()),
  ]
}

///|
pub fn policy_profile_for_type(book_type : String) -> PolicyProfile? {
  for profile in policy_profiles() {
    if profile.book_type == book_type {
      return Some(profile)
    }
  }
  None
}

///|
pub fn source_policy_for_type(book_type : String) -> String {
  match policy_profile_for_type(book_type) {
    Some(profile) => profile.source_policy
    None => book_first_policy()
  }
}

///|
pub fn policy_for_type(book_type : String) -> BookPolicy {
  match policy_profile_for_type(book_type) {
    Some(profile) => profile.policy
    None => general()
  }
}
