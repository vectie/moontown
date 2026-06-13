///|
pub fn web_first_policy() -> String {
  "web-first"
}

///|
pub fn book_first_policy() -> String {
  "book-first"
}

///|
pub fn source_policy_or_default(
  source_policy : String,
  default_policy : String,
) -> String {
  let normalized = source_policy.trim().to_owned()
  if normalized.is_empty() {
    default_policy
  } else {
    normalized
  }
}
