///|
async fn seed_civic_salon_protocol_slice(
  scenario : CivicSalonScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> Unit {
  let (inputs, contributions) = civic_salon_participant_protocol_records(
    scenario, protocol, participants, round_id, round_number,
  )
  let (reductions, outbox) = civic_salon_idea_protocol_records(
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
    civic_salon_home_return_records(
      scenario,
      protocol.building_id,
      ideas,
      round_id~,
    ).map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(protocol.building_id, "reviews", [
    civic_salon_review_gate_json(
      scenario, protocol, participants, ideas, round_id,
    ),
  ])
}
