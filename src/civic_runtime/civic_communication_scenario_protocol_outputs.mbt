///|
fn civic_communication_output_protocol_records(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  ideas : Array[CivicCommunicationIdea],
  round_id : String,
  round_number : Int,
) -> (Array[Json], Array[Json]) {
  let reductions : Array[Json] = []
  let outbox : Array[Json] = []
  for idea in ideas {
    reductions.push(
      civic_communication_reduction_json(
        scenario, protocol, idea, round_id, round_number,
      ),
    )
    outbox.push(
      civic_communication_outbox_json(
        scenario, protocol, idea, round_id, round_number,
      ),
    )
  }
  (reductions, outbox)
}

///|
fn civic_communication_reduction_json(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  idea : CivicCommunicationIdea,
  round_id : String,
  round_number : Int,
) -> Json {
  @civic.BuildingReductionResult::{
    id: "red-\{round_id}-\{idea.id}",
    building_id: protocol.building_id,
    reduction_kind: scenario.reduction_kind,
    decision: "update",
    summary: "\{idea.title}: \{idea.summary}",
    contribution_ids: idea.participating_books.map(fn(book_id) {
      "ctr-\{scenario.id}-\{round_id}-\{book_id}"
    }),
    output_channel: scenario.output_channel,
    distribution_targets: civic_communication_distribution_targets(
      scenario, idea,
    ),
    changed_pages: [scenario.backlog_path, scenario.synthesis_path],
    accepted_records: [idea.summary, "Next experiment: \{idea.next_experiment}"],
    review_items: [scenario.review_reason],
    review_status: "pending",
    idempotency_key: "\{scenario.id}/reduction/\{idea.id}/round-\{round_number}",
    related_book_id: protocol.book_id,
  }.to_json()
}

///|
fn civic_communication_distribution_targets(
  scenario : CivicCommunicationScenario,
  idea : CivicCommunicationIdea,
) -> Array[String] {
  [
    "moonbook:\{scenario.building_book_id}/\{scenario.backlog_path}",
    "projection:module/\{scenario.building_id}",
    ..idea.participating_books.map(fn(book_id) {
      "moonbook:\{book_id}/wiki/queries/open-questions.md"
    }),
  ]
}

///|
fn civic_communication_outbox_json(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  idea : CivicCommunicationIdea,
  round_id : String,
  round_number : Int,
) -> Json {
  @civic.BuildingDistributionRecord::{
    id: "out-\{round_id}-\{idea.id}",
    building_id: protocol.building_id,
    target_kind: "participant_question_backlog",
    target_id: protocol.book_id,
    target_path: scenario.backlog_path,
    summary: "Distributed reviewable pattern output `\{idea.title}` to \{idea.participating_books.length()} internal participant workspace(s).",
    review_status: "pending",
    idempotency_key: "\{scenario.id}/outbox/\{idea.id}/round-\{round_number}",
  }.to_json()
}

///|
fn civic_communication_review_gate_json(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
  round_id : String,
) -> Json {
  @civic.BuildingReviewGateRecord::{
    id: "rev-\{round_id}",
    building_id: protocol.building_id,
    gate: scenario.review_gate,
    status: "pending",
    reason: scenario.review_reason,
    related_packet_id: civic_communication_first_packet_id(
      scenario, participants, round_id,
    ),
    related_reduction_id: civic_communication_first_reduction_id(
      ideas, round_id,
    ),
    owner: scenario.review_owner,
  }.to_json()
}
