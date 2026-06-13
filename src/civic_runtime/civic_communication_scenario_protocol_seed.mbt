///|
async fn seed_civic_communication_protocol_slice(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
  round_id : String,
  round_number : Int,
) -> Unit {
  let (inputs, contributions) = civic_communication_participant_protocol_records(
    scenario, protocol, participants, round_id, round_number,
  )
  let (reductions, outbox) = civic_communication_output_protocol_records(
    scenario, protocol, ideas, round_id, round_number,
  )
  write_protocol_jsonl_records(
    protocol.building_id,
    "participants",
    participants.map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(
    protocol.building_id,
    "ideas",
    ideas.map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(protocol.building_id, "inbox", inputs)
  write_protocol_jsonl_records(
    protocol.building_id,
    "contributions",
    contributions,
  )
  write_protocol_jsonl_records(protocol.building_id, "reductions", reductions)
  write_protocol_jsonl_records(protocol.building_id, "outbox", outbox)
  write_protocol_jsonl_records(
    protocol.building_id,
    "home_returns",
    civic_communication_home_return_records(
      scenario,
      protocol.building_id,
      ideas,
      round_id~,
    ).map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(protocol.building_id, "reviews", [
    civic_communication_review_gate_json(
      scenario, protocol, participants, ideas, round_id,
    ),
  ])
}
