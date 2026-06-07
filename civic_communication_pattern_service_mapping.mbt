///|
fn civic_communication_pattern_for_service_kind(
  service_kind : String,
) -> String {
  match service_kind {
    "town-supervision" => "triage-desk"
    "resident-memory" => "review-council"
    "policy-service" => "triage-desk"
    "contest-service" => "review-council"
    "social-matching" => "match-market"
    "talent-graph" => "match-market"
    "vitality-analytics" => "signal-watch"
    "education-service" => "learning-cohort"
    "physical-bridge" => "incident-bridge"
    "market-service" => "match-market"
    "story-service" => "story-forge"
    _ => "triage-desk"
  }
}

///|
pub fn civic_communication_pattern_id_for_service(
  service : @civic.CivicServiceDefinition,
) -> String {
  civic_communication_pattern_for_service_kind(service.service_kind)
}
