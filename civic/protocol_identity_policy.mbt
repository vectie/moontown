///|
fn protocol_mode_for_service(service : CivicServiceDefinition) -> String {
  match service.module_mode {
    "exchange-place" => "exchange-reduce-distribute"
    "projection-surface" => "observe-reduce-project"
    "gateway" => "gate-reduce-handoff"
    "agent-workspace" => "work-reduce-persist"
    "hybrid" => "hybrid-exchange-reduce"
    _ => "module-reduce-distribute"
  }
}

///|
fn social_responsibility_for_service(
  service : CivicServiceDefinition,
) -> String {
  match service.id {
    "social-square" => "Consent-aware community matching and weak-tie exchange."
    "policy-hall" =>
      "Source-backed policy help that separates cited facts from interpretation."
    "contest-express" =>
      "Competition readiness coaching, submission review, and team preparation."
    "vitality-dashboard" =>
      "Town vitality accounting that separates real progress from operational noise."
    "physical-bridge" => "Confirmation-gated virtual-to-real service handoff."
    "valley-market" =>
      "Reviewable value exchange, points, rewards, and anti-abuse accounting."
    "broadcast-tower" =>
      "Public-safe story drafting from verified town achievements."
    "ai-garden" => "AI literacy tutoring and learning-quest generation."
    "talent-avenue" => "Trustworthy talent graph curation and project matching."
    "resident-twins" =>
      "Private resident memory with projection-safe public presence."
    "town-shell" =>
      "Mayor-level town supervision, routing, and operator projection."
    _ => service.purpose
  }
}

///|
fn participant_roles_for_service(
  service : CivicServiceDefinition,
) -> Array[String] {
  match service.id {
    "social-square" => ["resident", "matchmaker_agent", "reviewer", "mayor"]
    "policy-hall" => ["resident", "policy_agent", "reviewer", "mayor"]
    "physical-bridge" => ["operator", "bridge_agent", "offline_owner", "mayor"]
    "vitality-dashboard" => ["mayor", "observer_agent", "operator"]
    _ => ["operator", "module_agent", "reviewer", "mayor"]
  }
}
