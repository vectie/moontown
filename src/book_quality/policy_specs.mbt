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
fn book_first_policy_spec(
  book_type : String,
  repair_action : String,
  policy : @policy.BookPolicy,
) -> PolicySpec {
  policy_spec(book_type, repair_action, book_first_policy(), policy)
}

///|
fn policy_specs() -> Array[PolicySpec] {
  [
    policy_spec(
      research_type(),
      research_repair_action(),
      web_first_policy(),
      @policy.research(),
    ),
    book_first_policy_spec(
      course_type(),
      course_repair_action(),
      @policy.course(),
    ),
    book_first_policy_spec(
      planbook_type(),
      planbook_repair_action(),
      @policy.planbook(),
    ),
    book_first_policy_spec(
      cookbook_type(),
      cookbook_repair_action(),
      @policy.cookbook(),
    ),
    book_first_policy_spec(
      civic_type(),
      civic_repair_action(),
      @policy.civic_protocol(),
    ),
    book_first_policy_spec(
      operational_type(),
      operational_repair_action(),
      @policy.operational(),
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
  match policy_spec_for_type(book_type) {
    Some(spec) => spec.source_policy
    None => book_first_policy()
  }
}

///|
pub fn policy_for_type(book_type : String) -> @policy.BookPolicy {
  match policy_spec_for_type(book_type) {
    Some(spec) => spec.policy
    None => @policy.general()
  }
}

///|
pub fn repair_action_for_type(book_type : String) -> String {
  match policy_spec_for_type(book_type) {
    Some(spec) => spec.repair_action
    None => general_repair_action()
  }
}
