///|
fn civic_salon_reducer_packet(
  scenario : CivicSalonScenario,
  packet_id : String,
  round_id : String,
  round_number : Int,
) -> @moonclaw.ExternalProposalPacket {
  let pattern = @civic.salon_pattern_for_scenario(scenario)
  @moonclaw.ExternalProposalPacket::new(
    packet_id~,
    title="Reduce \{scenario.title} round \{round_number}",
    summary="Run the \{scenario.domain_label} \{pattern.title} reducer and emit CivicSalonIdea JSON for \{scenario.title}.",
    request_text=civic_salon_reducer_request(scenario, round_id, round_number),
    profile="civic_salon_reducer_worker",
    output_contract=pattern.output_contract,
    context_pages=[
      "raw/bootstrap/civic-salon-reducer-contract.md", "raw/bootstrap/civic-salon-participants.json",
      "raw/bootstrap/civic-salon-reducer-input.md",
    ],
    skill_paths=["skills/\{scenario.skill_name}/SKILL.md"],
    notes=[
      "Read the generated SKILL.md before reducing ideas.", "Do not use template-provided seed ideas; only participant context and contract files are input.",
      "Write raw/bootstrap/civic-salon-ideas.json with the exact CivicSalonIdea contract.",
    ],
    tags=[
      "civic-communication-pattern",
      pattern.id,
      "reducer",
      scenario.id,
      scenario.building_id,
    ],
    metadata=civic_salon_reducer_packet_metadata(
      scenario, pattern, round_id, round_number,
    ),
  )
}

///|
fn civic_salon_reducer_packet_metadata(
  scenario : CivicSalonScenario,
  pattern : @civic.CivicCommunicationPattern,
  round_id : String,
  round_number : Int,
) -> Json {
  let fields : Map[String, Json] = {}
  fields["producer"] = "moontown".to_json()
  fields["building_id"] = scenario.building_id.to_json()
  fields["book_id"] = scenario.building_book_id.to_json()
  fields["round_id"] = round_id.to_json()
  fields["round_number"] = round_number.to_json()
  fields["communication_pattern_id"] = pattern.id.to_json()
  fields["communication_pattern_title"] = pattern.title.to_json()
  @moonclaw_runtime.add_moonclaw_no_input_policy(fields)
  fields["profile_metadata"] = @moonclaw_runtime.moonclaw_no_input_policy_json()
  fields["step_metadata"] = civic_salon_reducer_packet_step_metadata(
    scenario, pattern,
  )
  Json::object(fields)
}

///|
fn civic_salon_reducer_packet_step_metadata(
  scenario : CivicSalonScenario,
  pattern : @civic.CivicCommunicationPattern,
) -> Json {
  let fields : Map[String, Json] = {}
  fields["kind"] = "civic_salon_reducer".to_json()
  fields["output_contract"] = pattern.output_contract.to_json()
  fields["preferred_skills"] = [scenario.skill_name].to_json()
  fields["target_pages"] = ["raw/bootstrap/civic-salon-ideas.json"].to_json()
  @moonclaw_runtime.add_moonclaw_no_input_policy(fields)
  Json::object(fields)
}

///|
fn civic_salon_reducer_request(
  scenario : CivicSalonScenario,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern = @civic.salon_pattern_for_scenario(scenario)
  [
    "You are the MoonClaw reducer for `\{scenario.title}` using the `\{pattern.title}` communication pattern.",
    "Round: `\{round_id}` (#\{round_number}).",
    "Read `skills/\{scenario.skill_name}/SKILL.md` first, then read the reducer contract and participant JSON.",
    "Reduce participant perspectives according to this pattern: \{pattern.summary}",
    "Write the result to `raw/bootstrap/civic-salon-ideas.json`.",
    "Do not wait for user input. If evidence is incomplete, produce best-effort pattern outputs with explicit follow-up questions and next experiments/artifacts.",
  ].join("\n")
}
