///|
async fn refresh_or_reconcile_civic_salon_schedule(
  schedule : CivicCommunicationSchedule,
  schedule_path : String,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
) -> String? {
  match
    reconcile_civic_salon_schedule_if_completed(
      schedule, snapshot_path, book_catalog_path, tick, now_ms,
    ) {
    Some((next, summary)) => {
      persist_civic_communication_schedule(schedule_path, schedule.id, next)
      Some(summary)
    }
    None =>
      refresh_civic_salon_projection_if_stale(
        schedule, snapshot_path, book_catalog_path,
      )
  }
}

///|
async fn reconcile_civic_salon_schedule_if_completed(
  schedule : CivicCommunicationSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
) -> (CivicCommunicationSchedule, String)? {
  if !civic_salon_schedule_has_active_round(schedule) {
    return None
  }
  match load_civic_salon_scenario_for_schedule(schedule, snapshot_path) {
    Some(scenario) =>
      reconcile_civic_salon_scenario_round(
        scenario, schedule, snapshot_path, book_catalog_path, tick, now_ms,
      )
    None => None
  }
}

///|
fn civic_salon_schedule_has_active_round(
  schedule : CivicCommunicationSchedule,
) -> Bool {
  schedule.enabled &&
  !schedule.latest_round_id.is_empty() &&
  civic_communication_summary_is_active(schedule.latest_summary)
}

///|
async fn reconcile_civic_salon_scenario_round(
  scenario : CivicCommunicationScenario,
  schedule : CivicCommunicationSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
) -> (CivicCommunicationSchedule, String)? {
  let workspace_base = civic_communication_workspace_base(snapshot_path)
  let reduction = reduce_civic_communication_outputs(
    scenario,
    round_id=schedule.latest_round_id,
    round_number=schedule.round_count + 1,
    workspace_base~,
    mode=PersistedReducer,
  )
  if !(reduction.status is @core.TaskExecutionStatus::Completed) ||
    reduction.ideas.length() == 0 {
    return None
  }
  let summary = materialize_civic_salon_scenario(
    scenario,
    reduction.ideas,
    book_catalog_path~,
    round_id=schedule.latest_round_id,
    round_number=schedule.round_count + 1,
    workspace_base~,
    reducer_summary=Some(reduction.summary),
  )
  let metrics = civic_communication_metrics(
    scenario,
    scenario.participants,
    reduction.ideas,
  )
  append_civic_salon_round_record(
    default_civic_communication_run_ledger_path(schedule.id, snapshot_path~),
    civic_communication_round_record(
      schedule,
      schedule.latest_round_id,
      tick,
      schedule.last_run_ms,
      @env.now(),
      metrics,
      "review",
      summary,
    ),
  )
  Some(
    (
      complete_civic_communication_schedule(
        schedule,
        now_ms,
        schedule.latest_round_id,
        summary,
      ),
      "\{schedule.id}: completed active reducer round \{schedule.latest_round_id}; \{summary}",
    ),
  )
}
