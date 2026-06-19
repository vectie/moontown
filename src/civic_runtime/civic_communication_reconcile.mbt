///|
async fn refresh_civic_communication_projection_if_stale(
  schedule : CivicCommunicationSchedule,
  snapshot_path : String,
  book_catalog_path : String,
) -> String? {
  if !schedule.enabled ||
    schedule.round_count <= 0 ||
    schedule.latest_round_id.is_empty() {
    return None
  }
  match
    load_civic_communication_scenario_for_schedule(schedule, snapshot_path) {
    Some(scenario) => {
      let projection_path = civic_communication_projection_path_for_scenario(
        scenario, snapshot_path,
      )
      let text = @support.read_text_or_empty(projection_path)
      let projection_current = text.contains(schedule.latest_round_id) &&
        text.contains("round \{schedule.round_count}")
      let protocol_ledgers_current = civic_communication_protocol_ledgers_current(
        schedule,
      )
      if projection_current && protocol_ledgers_current {
        None
      } else {
        let workspace_base = civic_communication_workspace_base(snapshot_path)
        let reduction = reduce_civic_communication_outputs(
          scenario,
          round_id=schedule.latest_round_id,
          round_number=schedule.round_count,
          workspace_base~,
          mode=PersistedReducer,
        )
        if reduction.status is Completed && reduction.ideas.length() > 0 {
          let summary = materialize_civic_communication_scenario(
            scenario,
            reduction.ideas,
            book_catalog_path~,
            round_id=schedule.latest_round_id,
            round_number=schedule.round_count,
            workspace_base~,
            reducer_summary=Some(reduction.summary),
          )
          Some(
            "\{schedule.id}: refreshed projection for \{schedule.latest_round_id}; \{summary}",
          )
        } else {
          Some(
            "\{schedule.id}: projection refresh skipped for \{schedule.latest_round_id}; \{reduction.summary}",
          )
        }
      }
    }
    _ => None
  }
}

///|
async fn civic_communication_protocol_ledgers_current(
  schedule : CivicCommunicationSchedule,
) -> Bool {
  for
    ledger in [
      "inbox", "contributions", "reductions", "outbox", "home_returns", "reviews",
    ] {
    let text = @support.read_text_or_empty(
      civic_communication_protocol_ledger_path(schedule.building_id, ledger),
    )
    if text.trim().is_empty() || !text.contains(schedule.latest_round_id) {
      return false
    }
  }
  true
}
