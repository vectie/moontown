///|
pub async fn bootstrap_civic_salon_scenario(
  scenario : CivicCommunicationScenario,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicCommunicationReductionMode = MoonClawReducer,
) -> String {
  let resolved_round_id = civic_pattern_round_id_for_scenario(
    scenario, round_id, round_number,
  )
  let reduction = reduce_civic_salon_ideas(
    scenario,
    round_id=resolved_round_id,
    round_number~,
    workspace_base~,
    mode=reducer_mode,
  )
  if reduction.status is @core.TaskExecutionStatus::Completed &&
    reduction.ideas.length() > 0 {
    materialize_civic_salon_scenario(
      scenario,
      reduction.ideas,
      book_catalog_path~,
      round_id=resolved_round_id,
      round_number~,
      workspace_base~,
      reducer_summary=Some(reduction.summary),
    )
  } else {
    write_civic_salon_reducer_blocker(scenario, reduction, resolved_round_id)
    civic_salon_blocked_summary(scenario, resolved_round_id, reduction.summary)
  }
}

///|
async fn materialize_civic_salon_scenario(
  scenario : CivicCommunicationScenario,
  ideas : Array[CivicCommunicationIdea],
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "civic-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_summary? : String? = None,
) -> String {
  if ideas.length() == 0 {
    return civic_salon_blocked_summary(
      scenario, round_id, "reducer produced no civic communication-pattern outputs.",
    )
  }
  let validation_errors = civic_salon_round_validation_errors(scenario, ideas)
  if validation_errors.length() > 0 {
    return civic_salon_blocked_summary(
      scenario,
      round_id,
      "invalid civic communication-pattern output: \{validation_errors.join("; ")}",
    )
  }
  let participants = scenario.participants
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let merged_catalog = merge_civic_salon_catalog(
    scenario, catalog, participants, workspace_base,
  )
  @moonbook.save_catalog_file(book_catalog_path, merged_catalog)
  for participant in participants {
    write_civic_salon_participant_workspace(
      scenario,
      participant,
      ideas,
      round_id,
      round_number,
      civic_salon_workspace_root(participant.book_id, workspace_base),
    )
  }
  let protocol = civic_communication_protocol_for_scenario(scenario)
  seed_civic_salon_protocol_slice(
    scenario, protocol, participants, ideas, round_id, round_number,
  )
  write_civic_salon_building_pages(
    scenario,
    protocol,
    participants,
    ideas,
    metrics,
    round_id,
    round_number,
    civic_salon_workspace_root(protocol.book_id, workspace_base),
  )
  ignore(write_wenyu_building_protocol_status())
  ignore(write_wenyu_civic_status())
  civic_salon_seeded_summary(
    scenario, round_id, participants, ideas, metrics, reducer_summary,
  )
}

///|
fn civic_salon_blocked_summary(
  scenario : CivicCommunicationScenario,
  round_id : String,
  reason : String,
) -> String {
  "Blocked \{scenario.title} \{round_id}: \{reason}"
}

///|
fn civic_salon_seeded_summary(
  scenario : CivicCommunicationScenario,
  round_id : String,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
  metrics : CivicCommunicationMetric,
  reducer_summary : String?,
) -> String {
  [
    civic_salon_seeded_summary_core(
      scenario, round_id, participants, ideas, metrics,
    ),
    civic_salon_seeded_reducer_suffix(reducer_summary),
  ].join("")
}

///|
fn civic_salon_seeded_summary_core(
  scenario : CivicCommunicationScenario,
  round_id : String,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
  metrics : CivicCommunicationMetric,
) -> String {
  [
    "Seeded \{scenario.title} \{round_id}:",
    "\{participants.length()} internal participant perspective(s),",
    "\{ideas.length()} reviewable pattern output(s),",
    "\{metrics.research_question_count} follow-up question(s),",
    "and \{metrics.idea_return_home_count} returned output-home route(s).",
  ].join(" ")
}

///|
fn civic_salon_seeded_reducer_suffix(reducer_summary : String?) -> String {
  match reducer_summary {
    Some(summary) => " Reducer: \{summary}"
    None => ""
  }
}

///|
fn civic_communication_protocol_for_scenario(
  scenario : CivicCommunicationScenario,
) -> @civic.BuildingProtocolDefinition {
  match @civic.wenyu_building_protocol_for_building_id(scenario.building_id) {
    Some(protocol) => protocol
    None => @civic.communication_protocol_for_scenario(scenario)
  }
}

///|
