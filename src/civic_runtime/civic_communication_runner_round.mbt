///|
async fn run_due_civic_salon_round(
  schedule : CivicCommunicationSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
  reducer_mode : CivicCommunicationReductionMode,
  run_inline : Bool,
) -> (CivicCommunicationSchedule, String) {
  match load_civic_salon_scenario_for_schedule(schedule, snapshot_path) {
    Some(scenario) =>
      run_civic_salon_scenario_round(
        scenario, schedule, snapshot_path, book_catalog_path, tick, now_ms, reducer_mode,
        run_inline,
      )
    None => run_unsupported_civic_salon_round(schedule, now_ms)
  }
}

///|
async fn run_civic_salon_scenario_round(
  scenario : CivicCommunicationScenario,
  schedule : CivicCommunicationSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
  reducer_mode : CivicCommunicationReductionMode,
  run_inline : Bool,
) -> (CivicCommunicationSchedule, String) {
  let round_id = civic_communication_round_id(schedule)
  let workspace_base = civic_salon_workspace_base(snapshot_path)
  let reduction = reduce_civic_communication_outputs(
    scenario,
    round_id~,
    round_number=schedule.round_count + 1,
    workspace_base~,
    mode=reducer_mode,
    run_inline~,
  )
  let ideas = reduction.ideas
  let metrics = civic_communication_metrics(
    scenario,
    scenario.participants,
    ideas,
  )
  let (decision, summary) = civic_salon_round_decision_summary(
    scenario, schedule, book_catalog_path, workspace_base, round_id, reduction, ideas,
  )
  append_civic_salon_round_record(
    default_civic_salon_run_ledger_path(schedule.id, snapshot_path~),
    civic_communication_round_record(
      schedule,
      round_id,
      tick,
      now_ms,
      @env.now(),
      metrics,
      decision,
      summary,
    ),
  )
  if decision == "review" {
    (
      complete_civic_communication_schedule(schedule, now_ms, round_id, summary),
      "\{round_id}: \{summary}",
    )
  } else {
    (
      retry_civic_salon_schedule(schedule, now_ms, round_id, summary),
      "\{round_id}: \{summary}",
    )
  }
}

///|
async fn civic_salon_round_decision_summary(
  scenario : CivicCommunicationScenario,
  schedule : CivicCommunicationSchedule,
  book_catalog_path : String,
  workspace_base : String,
  round_id : String,
  reduction : CivicCommunicationReductionResult,
  ideas : Array[CivicCommunicationIdea],
) -> (String, String) {
  let validation_errors = if reduction.status
    is @core.TaskExecutionStatus::Completed {
    civic_salon_round_validation_errors(scenario, ideas)
  } else {
    []
  }
  if reduction.status is @core.TaskExecutionStatus::Completed &&
    ideas.length() > 0 &&
    validation_errors.length() == 0 {
    return (
      "review",
      materialize_civic_salon_scenario(
        scenario,
        ideas,
        book_catalog_path~,
        round_id~,
        round_number=schedule.round_count + 1,
        workspace_base~,
        reducer_summary=Some(reduction.summary),
      ),
    )
  }
  if validation_errors.length() > 0 {
    return (
      "blocked",
      "Blocked \{scenario.title} \{round_id}: invalid civic communication-pattern output: \{validation_errors.join("; ")}",
    )
  }
  if civic_communication_reduction_status_live(reduction.status) {
    return (
      "running",
      "Running \{scenario.title} \{round_id}: \{reduction.summary}",
    )
  }
  write_civic_communication_reducer_blocker(scenario, reduction, round_id)
  ("blocked", "Blocked \{scenario.title} \{round_id}: \{reduction.summary}")
}
