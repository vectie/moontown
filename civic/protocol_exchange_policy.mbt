///|
fn aggregation_policy_for_service(service : CivicServiceDefinition) -> String {
  match service.id {
    "social-square" =>
      "Group compatible interests, needs, and events without exposing private resident memory."
    "vitality-dashboard" =>
      "Group operational records by real-progress impact, not by raw activity volume."
    _ =>
      "Group incoming packets by civic purpose, risk, review state, and the module's MoonBook role."
  }
}

///|
fn exchange_policy_for_service(service : CivicServiceDefinition) -> String {
  match service.id {
    "social-square" =>
      "Exchange identifying resident details only after explicit consent."
    "physical-bridge" =>
      "Exchange offline action details only after operator confirmation."
    "resident-twins" =>
      "Exchange private resident memory only through projection-safe summaries."
    _ =>
      "Exchange only the minimum context needed for the module-native decision and preserve review gates."
  }
}

///|
fn reduction_policy_for_service(service : CivicServiceDefinition) -> String {
  match service.id {
    "social-square" =>
      "Let the matchmaker skill choose a consent request, match candidate, event plan, no-change digest, or review blocker."
    "policy-hall" =>
      "Let the policy skill choose a cited checklist, eligibility answer, source gap, or review blocker."
    "vitality-dashboard" =>
      "Let the observability skill choose a health digest, recovery queue item, false-progress note, or no-change status."
    _ =>
      "Let the dedicated skill choose the smallest useful building-native output inside the protocol envelope."
  }
}

///|
fn distribution_policy_for_service(service : CivicServiceDefinition) -> String {
  match service.id {
    "social-square" =>
      "Send consent requests to residents, review items to MoonBook, and public summaries to projection."
    "physical-bridge" =>
      "Send blockers and handoff packets to operator review before any external/offline action."
    _ =>
      "Send accepted records to MoonBook, review-gated records to review queues, and projection-safe summaries to Moontown UI."
  }
}
