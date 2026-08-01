///|
pub fn marketplace_schema() -> String {
  "moontown.marketplace-store.v2"
}

///|
pub fn empty_marketplace_state() -> MarketplaceState {
  {
    schema: marketplace_schema(),
    principals: [],
    sessions: [],
    agent_listings: [],
    building_listings: [],
    channels: [],
    messages: [],
    share_grants: [],
    subscriptions: [],
    notifications: [],
    sponsored_placements: [],
    action_requests: [],
    version: 1,
  }
}

///|
fn normalized_string(value : String) -> String {
  value.trim().to_owned()
}

///|
fn normalized_terms(values : Array[String]) -> Array[String] {
  let terms : Array[String] = []
  for raw in values {
    let value = raw.trim().to_owned().to_lower()
    if !value.is_empty() && !terms.contains(value) {
      terms.push(value)
    }
  }
  terms.sort()
  terms
}

///|
fn valid_symbolic_id(value : String) -> Bool {
  let trimmed = value.trim().to_owned()
  if trimmed.is_empty() || trimmed.length() > 128 {
    return false
  }
  for char in trimmed {
    if !((char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      char == '-' ||
      char == '_' ||
      char == '.' ||
      char == ':') {
      return false
    }
  }
  true
}

///| Cross-product public index IDs are intentionally narrower than internal

///|
/// symbolic IDs so MoonFind and every consuming pack share one grammar.
fn valid_public_index_id(value : String) -> Bool {
  if value.is_empty() ||
    value.length() > 128 ||
    value.has_prefix("-") ||
    value.has_prefix(".") ||
    value.has_prefix(":") ||
    value.has_suffix("-") ||
    value.has_suffix(".") ||
    value.has_suffix(":") {
    return false
  }
  for char in value {
    if !((char >= 'a' && char <= 'z') ||
      (char >= '0' && char <= '9') ||
      char == '.' ||
      char == ':' ||
      char == '-') {
      return false
    }
  }
  true
}

///|
fn validate_public_text(
  label : String,
  value : String,
  max_length : Int,
) -> String raise {
  let normalized = normalized_string(value)
  let lower = normalized.to_lower()
  if normalized.is_empty() || normalized.length() > max_length {
    fail("\{label} must contain 1..\{max_length} public characters")
  }
  if lower.contains("/users/") ||
    lower.contains("/home/") ||
    lower.contains("file://") ||
    lower.contains("workspace_root") ||
    lower.contains("api_key") ||
    lower.contains("authorization") ||
    lower.contains("bearer ") ||
    lower.contains("oauth") ||
    lower.contains("private key") ||
    lower.contains("chain-of-thought") {
    fail("\{label} contains prohibited private material")
  }
  normalized
}

///|
fn publication_lifecycle_draft() -> PublicationLifecycle {
  {
    state: PublicationDraft,
    shared_at_ms: None,
    submitted_at_ms: None,
    published_at_ms: None,
    archived_at_ms: None,
    reviewed_by: None,
    review_summary: "",
  }
}
