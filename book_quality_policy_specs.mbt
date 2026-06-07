///|
struct BookQualityPolicySpec {
  book_type : String
  repair_action : String
  source_policy : String
} derive(Debug, Eq)

///|
fn book_quality_web_first_policy() -> String {
  "web-first"
}

///|
fn book_quality_book_first_policy() -> String {
  "book-first"
}

///|
fn book_quality_policy_spec(
  book_type : String,
  repair_action : String,
  source_policy : String,
) -> BookQualityPolicySpec {
  { book_type, repair_action, source_policy }
}

///|
fn book_first_quality_policy_spec(
  book_type : String,
  repair_action : String,
) -> BookQualityPolicySpec {
  book_quality_policy_spec(
    book_type,
    repair_action,
    book_quality_book_first_policy(),
  )
}

///|
fn book_quality_policy_specs() -> Array[BookQualityPolicySpec] {
  [
    book_quality_policy_spec(
      book_quality_research_type(),
      research_book_repair_action(),
      book_quality_web_first_policy(),
    ),
    book_first_quality_policy_spec(
      book_quality_course_type(),
      course_book_repair_action(),
    ),
    book_first_quality_policy_spec(
      book_quality_planbook_type(),
      planbook_repair_action(),
    ),
    book_first_quality_policy_spec(
      book_quality_cookbook_type(),
      cookbook_repair_action(),
    ),
    book_first_quality_policy_spec(
      book_quality_civic_type(),
      civic_protocol_support_repair_action(),
    ),
    book_first_quality_policy_spec(
      book_quality_operational_type(),
      operational_book_repair_action(),
    ),
  ]
}

///|
fn book_quality_policy_spec_for_type(
  book_type : String,
) -> BookQualityPolicySpec? {
  for spec in book_quality_policy_specs() {
    if spec.book_type == book_type {
      return Some(spec)
    }
  }
  None
}

///|
fn book_quality_source_policy_for_type(book_type : String) -> String {
  match book_quality_policy_spec_for_type(book_type) {
    Some(spec) => spec.source_policy
    None => book_quality_book_first_policy()
  }
}
