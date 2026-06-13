///|
fn civic_salon_participant_protocol_records(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicCommunicationParticipantBook],
  round_id : String,
  round_number : Int,
) -> (Array[Json], Array[Json]) {
  let inputs : Array[Json] = []
  let contributions : Array[Json] = []
  for participant in participants {
    let input_id = civic_salon_input_packet_id(scenario, participant, round_id)
    inputs.push(
      civic_salon_input_packet_json(
        scenario, protocol, participant, input_id, round_id, round_number,
      ),
    )
    contributions.push(
      civic_salon_contribution_json(
        scenario, protocol, participant, input_id, round_id, round_number,
      ),
    )
  }
  (inputs, contributions)
}

///|
fn civic_salon_input_packet_id(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
  round_id : String,
) -> String {
  "pkt-\{scenario.id}-\{round_id}-\{participant.book_id}"
}

///|
fn civic_salon_input_packet_json(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participant : CivicCommunicationParticipantBook,
  input_id : String,
  round_id : String,
  round_number : Int,
) -> Json {
  @civic.BuildingInputPacket::{
    id: input_id,
    building_id: protocol.building_id,
    source_kind: "participant_workspace",
    source_id: participant.book_id,
    channel: scenario.protocol_channel,
    privacy_label: "book-public",
    summary: "\{participant.title} joins \{scenario.title} on \{participant.cadence}.",
    payload: "focus=\{participant.focus_area}; question=\{participant.current_question}; contribution=\{participant.contribution}",
    review_status: "accepted",
    idempotency_key: "\{scenario.id}/\{participant.book_id}/round-\{round_number}",
    related_book_id: participant.book_id,
    related_task_id: round_id,
    related_run_id: "protocol-seed",
  }.to_json()
}

///|
fn civic_salon_contribution_json(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participant : CivicCommunicationParticipantBook,
  input_id : String,
  round_id : String,
  round_number : Int,
) -> Json {
  @civic.BuildingContribution::{
    id: "ctr-\{scenario.id}-\{round_id}-\{participant.book_id}",
    building_id: protocol.building_id,
    contribution_kind: "participant_perspective",
    input_packet_ids: [input_id],
    summary: participant.contribution,
    basis: [
      "Internal participant workspace: \{participant.book_id}",
      "Focus area: \{participant.focus_area}",
      "Current question: \{participant.current_question}",
    ],
    confidence: "medium",
    privacy_label: "book-public",
    review_status: "accepted",
    idempotency_key: "\{scenario.id}/contribution/\{participant.book_id}/round-\{round_number}",
  }.to_json()
}
