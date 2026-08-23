///|
pub fn projection_contract_id() -> String {
  "moontown.pack-projection.v1"
}

///|
pub fn candidate_contract_id() -> String {
  "moontown.pack-candidate-intake.v1"
}

///|
pub fn projection_provider_port_id() -> String {
  "moontown-pack-projection"
}

///|
pub fn projection_provider_port_version() -> String {
  "1.0.0"
}

///|
pub fn candidate_input_schema_id() -> String {
  "town-pack-candidate"
}

///|
pub fn pack_lifecycle_contract_id() -> String {
  "moonsuite.pack-lifecycle.v1"
}

///|
pub fn pack_lifecycle_event_contract_id() -> String {
  "moonsuite.pack-lifecycle-event.v1"
}

///|
pub fn candidate_receipt_contract_id() -> String {
  "moontown.pack-candidate-receipt.v1"
}

///|
pub fn pack_lifecycle_stages() -> Array[String] {
  [
    "draft", "validated", "installed", "active", "projecting", "degraded", "inactive",
  ]
}

///|
pub fn pack_lifecycle_event_kinds() -> Array[String] {
  [
    "validated", "installed", "activated", "projection-accepted", "projection-rejected",
    "verification-failed", "deactivated",
  ]
}

///|
pub fn candidate_receipt_statuses() -> Array[String] {
  [
    "submitted", "routed", "review-pending", "accepted", "rejected", "withdrawn",
    "blocked",
  ]
}

///|
pub fn projection_schema_path() -> String {
  "schemas/pack-town-projection.schema.json"
}

///|
pub fn candidate_schema_path() -> String {
  "schemas/town-pack-candidate.schema.json"
}
