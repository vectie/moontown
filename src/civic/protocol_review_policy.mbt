///|
fn review_gates_for_service(service : CivicServiceDefinition) -> Array[String] {
  match service.id {
    "social-square" => ["external_introduction", "sensitive_profile_change"]
    "policy-hall" => ["application_advice", "uncited_policy_claim"]
    "physical-bridge" => ["offline_action", "device_or_venue_handoff"]
    "valley-market" => ["redemption", "points_balance_change", "abuse_risk"]
    "broadcast-tower" => ["public_broadcast", "personal_story"]
    "resident-twins" => ["private_memory_change", "projection_scope_change"]
    _ => ["public_output", "external_action", "sensitive_data"]
  }
}

///|
fn privacy_scope_for_service(service : CivicServiceDefinition) -> String {
  match service.id {
    "resident-twins" =>
      "private-memory-first, projection-safe by explicit scope"
    "social-square" =>
      "projection-safe by default, consent required for identities"
    "physical-bridge" => "operator-confirmed handoff only"
    _ => "projection-safe by default"
  }
}
