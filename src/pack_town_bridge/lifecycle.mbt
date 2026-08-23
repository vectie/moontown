///|
pub fn draft_pack_lifecycle(
  pack_id : String,
  version : String,
  created_at : String,
) -> PackLifecycleRecord {
  {
    contract_id: pack_lifecycle_contract_id(),
    pack_id,
    version,
    stage: "draft",
    sequence: 0,
    updated_at: created_at,
    last_projection_at: None,
    issue: None,
    evidence_refs: [],
    applied_event_ids: [],
  }
}

///|
fn expected_next_stages(stage : String, kind : String) -> String? {
  match (stage, kind) {
    ("draft", "validated") => Some("validated")
    ("validated", "installed") => Some("installed")
    ("installed", "activated") | ("inactive", "activated") => Some("active")
    ("active", "projection-accepted")
    | ("projecting", "projection-accepted")
    | ("degraded", "projection-accepted") => Some("projecting")
    ("active", "projection-rejected")
    | ("projecting", "projection-rejected")
    | ("degraded", "projection-rejected")
    | (_, "verification-failed") => Some("degraded")
    ("installed", "deactivated")
    | ("active", "deactivated")
    | ("projecting", "deactivated")
    | ("degraded", "deactivated") => Some("inactive")
    _ => None
  }
}

///|
pub fn reduce_pack_lifecycle(
  record : PackLifecycleRecord,
  event : PackLifecycleEvent,
) -> Result[PackLifecycleRecord, String] {
  if record.contract_id != pack_lifecycle_contract_id() {
    return Err("unsupported pack lifecycle record contract")
  }
  if event.contract_id != pack_lifecycle_event_contract_id() {
    return Err("unsupported pack lifecycle event contract")
  }
  if event.event_id.trim().is_empty() || event.occurred_at.trim().is_empty() {
    return Err("lifecycle event identity and time are required")
  }
  if record.pack_id != event.pack_id || record.version != event.version {
    return Err("lifecycle event does not match the pack version")
  }
  if record.applied_event_ids.contains(event.event_id) {
    return Ok(record)
  }
  guard expected_next_stages(record.stage, event.kind) is Some(next_stage) else {
    return Err(
      "invalid pack lifecycle transition: \{record.stage} + \{event.kind}",
    )
  }
  if ["projection-rejected", "verification-failed"].contains(event.kind) &&
    event.issue is None {
    return Err("\{event.kind} requires an issue")
  }
  let last_projection_at = if event.kind == "projection-accepted" {
    Some(event.occurred_at)
  } else {
    record.last_projection_at
  }
  let issue = if next_stage == "degraded" { event.issue } else { None }
  Ok({
    ..record,
    stage: next_stage,
    sequence: record.sequence + 1,
    updated_at: event.occurred_at,
    last_projection_at,
    issue,
    evidence_refs: record.evidence_refs + event.evidence_refs,
    applied_event_ids: record.applied_event_ids + [event.event_id],
  })
}

///|
pub fn submitted_candidate_receipt(
  candidate : TownPackCandidate,
  submitted_at : String,
) -> PackCandidateReceipt {
  {
    contract_id: candidate_receipt_contract_id(),
    candidate_ref: candidate.candidate_ref,
    pack_id: candidate.target_pack_id,
    operation_id: candidate.intake_operation_id,
    status: "submitted",
    sequence: 0,
    updated_at: submitted_at,
    evidence_refs: candidate.evidence_refs,
    issue: None,
  }
}

///|
fn candidate_next_status(status : String, event : String) -> String? {
  match (status, event) {
    ("submitted", "route") => Some("routed")
    ("routed", "request-review") => Some("review-pending")
    ("routed", "accept") | ("review-pending", "accept") => Some("accepted")
    ("routed", "reject") | ("review-pending", "reject") => Some("rejected")
    ("submitted", "withdraw")
    | ("routed", "withdraw")
    | ("review-pending", "withdraw") => Some("withdrawn")
    ("submitted", "block")
    | ("routed", "block")
    | ("review-pending", "block") => Some("blocked")
    _ => None
  }
}

///|
pub fn transition_candidate_receipt(
  receipt : PackCandidateReceipt,
  event : String,
  occurred_at : String,
  evidence_refs : Array[String],
  issue? : String? = None,
) -> Result[PackCandidateReceipt, String] {
  if receipt.contract_id != candidate_receipt_contract_id() {
    return Err("unsupported candidate receipt contract")
  }
  guard candidate_next_status(receipt.status, event) is Some(next_status) else {
    return Err("invalid candidate transition: \{receipt.status} + \{event}")
  }
  if ["reject", "block"].contains(event) && issue is None {
    return Err("\{event} requires an issue")
  }
  Ok({
    ..receipt,
    status: next_status,
    sequence: receipt.sequence + 1,
    updated_at: occurred_at,
    evidence_refs: receipt.evidence_refs + evidence_refs,
    issue: if ["rejected", "blocked"].contains(next_status) {
      issue
    } else {
      None
    },
  })
}
