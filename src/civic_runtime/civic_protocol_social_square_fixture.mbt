///|
async fn seed_social_square_protocol_slice(
  protocol : @civic.BuildingProtocolDefinition,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> Unit {
  let input = @civic.BuildingInputPacket::{
    id: "pkt-social-square-resident-intro-001",
    building_id: protocol.building_id,
    source_kind: "resident_request",
    source_id: "resident-projection/demo-founder",
    channel: "resident_request",
    privacy_label: "projection-safe",
    summary: "A resident founder asks for a low-risk peer introduction around youth AI education events.",
    payload: "interest=AI education; need=community event partner; consent=not-yet-granted",
    review_status: "draft",
    idempotency_key: "social-square/demo-founder/intro-001",
    related_book_id: protocol.book_id,
    related_task_id: "",
    related_run_id: "",
  }
  let contribution = @civic.BuildingContribution::{
    id: "ctr-social-square-compatible-interest-001",
    building_id: protocol.building_id,
    contribution_kind: "match_hypothesis",
    input_packet_ids: [input.id],
    summary: "Projection-safe interests suggest a possible education-event collaboration, but identity exchange still requires consent.",
    basis: [
      "resident request names AI education as an interest", "request asks for a community event partner",
      "no explicit consent for external introduction is present",
    ],
    confidence: "medium",
    privacy_label: "projection-safe",
    review_status: "draft",
    idempotency_key: "social-square/contribution/compatible-interest-001",
  }
  let reduction = @civic.BuildingReductionResult::{
    id: "red-social-square-consent-gate-001",
    building_id: protocol.building_id,
    reduction_kind: "consent_gated_match_candidate",
    decision: "needs_review",
    summary: "Social Square reduced one resident request into a consent-gated match candidate and review item instead of publishing an introduction.",
    contribution_ids: [contribution.id],
    output_channel: "review_item",
    distribution_targets: [
      "moonbook:wiki/reviews/social-introductions.md", "projection:module/social-square",
    ],
    changed_pages: ["wiki/reviews/social-introductions.md"],
    accepted_records: [
      "match candidate requires consent before identity exchange",
    ],
    review_items: ["external_introduction consent gate pending"],
    review_status: "pending",
    idempotency_key: "social-square/reduction/consent-gate-001",
    related_book_id: protocol.book_id,
  }
  let distribution = @civic.BuildingDistributionRecord::{
    id: "out-social-square-review-001",
    building_id: protocol.building_id,
    target_kind: "moonbook_review_queue",
    target_id: protocol.book_id,
    target_path: "wiki/reviews/social-introductions.md",
    summary: "Queued a consent-gated match candidate for keeper/operator review.",
    review_status: "pending",
    idempotency_key: "social-square/outbox/review-001",
  }
  let review = @civic.BuildingReviewGateRecord::{
    id: "rev-social-square-external-intro-001",
    building_id: protocol.building_id,
    gate: "external_introduction",
    status: "pending",
    reason: "No explicit consent exists for resident-identifying introduction.",
    related_packet_id: input.id,
    related_reduction_id: reduction.id,
    owner: "operator",
  }
  write_protocol_jsonl_record(
    protocol.building_id,
    "inbox",
    input.to_json(),
    ledger_base_dir~,
  )
  write_protocol_jsonl_record(
    protocol.building_id,
    "contributions",
    contribution.to_json(),
    ledger_base_dir~,
  )
  write_protocol_jsonl_record(
    protocol.building_id,
    "reductions",
    reduction.to_json(),
    ledger_base_dir~,
  )
  write_protocol_jsonl_record(
    protocol.building_id,
    "outbox",
    distribution.to_json(),
    ledger_base_dir~,
  )
  write_protocol_jsonl_record(
    protocol.building_id,
    "reviews",
    review.to_json(),
    ledger_base_dir~,
  )
}
