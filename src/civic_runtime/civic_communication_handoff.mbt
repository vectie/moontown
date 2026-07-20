///|
pub async fn bootstrap_civic_communication_handoff_file(
  handoff_path : String,
  receipt_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicCommunicationReductionMode = MoonClawReducer,
) -> String {
  let handoff = match load_civic_communication_handoff_file(handoff_path) {
    Some(value) => value
    None => return "Could not load civic communication handoff: \{handoff_path}"
  }
  let resolved_round_id = civic_pattern_round_id_for_scenario(
    handoff.scenario,
    round_id,
    round_number,
  )
  let errors = @civic.validate_civic_communication_handoff(handoff)
  if errors.length() > 0 {
    let receipt = civic_communication_handoff_receipt(
      handoff,
      resolved_round_id,
      round_number,
      workspace_base,
      reducer_mode,
      "rejected",
      0,
      "Blocked civic communication handoff: \{errors.join("; ")}",
    )
    write_civic_communication_handoff_receipt(receipt_path, receipt)
    return receipt.to_json().stringify(indent=2)
  }
  let summary = bootstrap_civic_communication_scenario(
    handoff.scenario,
    book_catalog_path~,
    round_id=resolved_round_id,
    round_number~,
    workspace_base~,
    reducer_mode~,
  )
  install_civic_communication_scenario_for_daemon(
    handoff.scenario,
    workspace_base,
    resolved_round_id,
    round_number,
    summary,
  )
  let completed = !summary.has_prefix("Blocked ")
  let output_count = if completed {
    load_persisted_civic_communication_reducer_output(
      handoff.scenario,
      workspace_base,
    )
    .map(fn(ideas) { ideas.length() })
    .unwrap_or(0)
  } else {
    0
  }
  let receipt = civic_communication_handoff_receipt(
    handoff,
    resolved_round_id,
    round_number,
    workspace_base,
    reducer_mode,
    if completed {
      "completed"
    } else {
      "blocked"
    },
    output_count,
    summary,
  )
  write_civic_communication_handoff_receipt(receipt_path, receipt)
  receipt.to_json().stringify(indent=2)
}

///|
async fn load_civic_communication_handoff_file(
  path : String,
) -> @civic.CivicCommunicationScenarioHandoff? {
  let parsed = match @support.read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn write_civic_communication_handoff_receipt(
  path : String,
  receipt : @civic.CivicCommunicationExecutionReceipt,
) -> Unit {
  @support.write_text_file(path, receipt.to_json().stringify(indent=2))
}

///|
fn civic_communication_handoff_receipt(
  handoff : @civic.CivicCommunicationScenarioHandoff,
  round_id : String,
  round_number : Int,
  workspace_base : String,
  reducer_mode : CivicCommunicationReductionMode,
  status : String,
  output_count : Int,
  summary : String,
) -> @civic.CivicCommunicationExecutionReceipt {
  let scenario = handoff.scenario
  let root = civic_communication_workspace_root(
    scenario.building_book_id,
    workspace_base,
  )
  {
    contract_version: @civic.civic_communication_receipt_contract_version(),
    handoff_id: handoff.handoff_id,
    producer: handoff.producer,
    producer_run_id: handoff.producer_run_id,
    consumer: "moontown",
    scenario_id: scenario.id,
    round_id,
    round_number,
    status,
    reducer_kind: civic_communication_reducer_kind(reducer_mode),
    participant_count: scenario.participants.length(),
    reviewable_output_count: output_count,
    review_status: if status == "completed" {
      "pending"
    } else {
      "blocked"
    },
    building_book_id: scenario.building_book_id,
    artifact_refs: if status == "completed" {
      [
        "\{root}/\{scenario.synthesis_path}",
        "\{root}/\{scenario.review_path}",
        "\{root}/\{scenario.metrics_path}",
        civic_communication_scenario_output_path(scenario, workspace_base),
      ]
    } else {
      []
    },
    summary,
  }
}

///|
fn civic_communication_reducer_kind(
  mode : CivicCommunicationReductionMode,
) -> String {
  match mode {
    MoonClawReducer => "moonclaw"
    PersistedReducer => "persisted"
    FixtureReducer => "fixture"
  }
}
