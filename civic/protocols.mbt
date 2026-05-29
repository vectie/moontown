///|
pub(all) struct BuildingProtocolDefinition {
  building_id : String
  service_id : String
  title : String
  book_id : String
  protocol_mode : String
  persistence_mode : String
  social_responsibility : String
  participant_roles : Array[String]
  input_channels : Array[String]
  output_channels : Array[String]
  aggregation_policy : String
  exchange_policy : String
  reduction_policy : String
  distribution_policy : String
  review_gates : Array[String]
  privacy_scope : String
  moonbook_role : String
  skill_packs : Array[String]
  projection_contract : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingInputPacket {
  id : String
  building_id : String
  source_kind : String
  source_id : String
  channel : String
  privacy_label : String
  summary : String
  payload : String
  review_status : String
  idempotency_key : String
  related_book_id : String
  related_task_id : String
  related_run_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingContribution {
  id : String
  building_id : String
  contribution_kind : String
  input_packet_ids : Array[String]
  summary : String
  basis : Array[String]
  confidence : String
  privacy_label : String
  review_status : String
  idempotency_key : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingReductionResult {
  id : String
  building_id : String
  reduction_kind : String
  decision : String
  summary : String
  contribution_ids : Array[String]
  output_channel : String
  distribution_targets : Array[String]
  changed_pages : Array[String]
  accepted_records : Array[String]
  review_items : Array[String]
  review_status : String
  idempotency_key : String
  related_book_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingDistributionRecord {
  id : String
  building_id : String
  target_kind : String
  target_id : String
  target_path : String
  summary : String
  review_status : String
  idempotency_key : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingReviewGateRecord {
  id : String
  building_id : String
  gate : String
  status : String
  reason : String
  related_packet_id : String
  related_reduction_id : String
  owner : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingProtocolSnapshot {
  building_id : String
  title : String
  book_id : String
  protocol_mode : String
  persistence_mode : String
  social_responsibility : String
  status : String
  ready : Bool
  inbox_count : Int
  contribution_count : Int
  reduction_count : Int
  outbox_count : Int
  review_count : Int
  latest_reduction_summary : String
  latest_distribution_summary : String
  skill_packs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingProtocolPortfolio {
  total : Int
  ready_count : Int
  active_count : Int
  review_count : Int
  blocked_count : Int
  status_path : String
  registry_path : String
  protocols : Array[BuildingProtocolSnapshot]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn wenyu_building_protocols() -> Array[BuildingProtocolDefinition] {
  wenyu_civic_services().map(wenyu_building_protocol_for_service)
}

///|
pub fn wenyu_building_protocol_for_service(
  service : CivicServiceDefinition,
) -> BuildingProtocolDefinition {
  {
    building_id: service.id,
    service_id: service.id,
    title: service.title,
    book_id: service.book_id,
    protocol_mode: protocol_mode_for_service(service),
    persistence_mode: service.persistence_mode,
    social_responsibility: social_responsibility_for_service(service),
    participant_roles: participant_roles_for_service(service),
    input_channels: input_channels_for_service(service),
    output_channels: output_channels_for_service(service),
    aggregation_policy: aggregation_policy_for_service(service),
    exchange_policy: exchange_policy_for_service(service),
    reduction_policy: reduction_policy_for_service(service),
    distribution_policy: distribution_policy_for_service(service),
    review_gates: review_gates_for_service(service),
    privacy_scope: privacy_scope_for_service(service),
    moonbook_role: service.book_role,
    skill_packs: ["wenyu-civic-service", service.skill_pack],
    projection_contract: service.output_contract,
  }
}

///|
pub fn wenyu_building_protocol_for_building_id(
  building_id : String,
) -> BuildingProtocolDefinition? {
  let key = civic_binding_key(building_id)
  for protocol in wenyu_building_protocols() {
    if civic_binding_key(protocol.building_id) == key {
      return Some(protocol)
    }
  }
  None
}

///|
pub fn wenyu_building_protocol_for_book_id(
  book_id : String,
) -> BuildingProtocolDefinition? {
  match wenyu_civic_service_for_book_id(book_id) {
    Some(service) => Some(wenyu_building_protocol_for_service(service))
    None => None
  }
}

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

///|
fn input_channels_for_service(
  service : CivicServiceDefinition,
) -> Array[String] {
  match service.id {
    "social-square" =>
      ["resident_request", "profile_projection", "event_signal"]
    "policy-hall" =>
      ["resident_question", "official_source", "eligibility_context"]
    "contest-express" => ["contest_call", "team_profile", "submission_draft"]
    "vitality-dashboard" =>
      ["daemon_event", "watcher_record", "worker_status", "projection_signal"]
    "physical-bridge" =>
      ["handoff_request", "venue_constraint", "operator_confirmation"]
    "valley-market" => ["offer", "need", "points_event", "abuse_signal"]
    "broadcast-tower" => ["achievement_signal", "event_record", "approved_fact"]
    _ => ["module_request", "book_signal", "worker_result"]
  }
}

///|
fn output_channels_for_service(
  service : CivicServiceDefinition,
) -> Array[String] {
  match service.id {
    "social-square" =>
      ["consent_request", "match_candidate", "event_plan", "review_item"]
    "policy-hall" =>
      ["cited_checklist", "eligibility_answer", "uncertainty_review"]
    "contest-express" =>
      ["readiness_plan", "mock_judge_feedback", "revision_queue"]
    "vitality-dashboard" =>
      ["health_digest", "recovery_item", "false_progress_note"]
    "physical-bridge" => ["handoff_packet", "confirmation_request", "blocker"]
    "valley-market" => ["ledger_update", "redemption_review", "abuse_review"]
    "broadcast-tower" => ["story_draft", "redaction_task", "public_highlight"]
    _ => ["module_result", "review_item", "projection_update"]
  }
}

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
