///|
pub async fn run_due_civic_salons(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  tick? : Int = 0,
  now_ms? : UInt64 = @env.now(),
  reducer_mode? : CivicSalonReductionMode = MoonClawReducer,
) -> String {
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
  let updated : Array[CivicSalonSchedule] = []
  let summaries : Array[String] = []
  let refreshes : Array[String] = []
  for schedule in schedules {
    if civic_salon_is_due(schedule, now_ms) {
      let (next, summary) = run_due_civic_salon_round(
        schedule, snapshot_path, book_catalog_path, tick, now_ms, reducer_mode,
      )
      updated.push(next)
      summaries.push(summary)
    } else {
      match
        refresh_civic_salon_projection_if_stale(
          schedule, snapshot_path, book_catalog_path,
        ) {
        Some(summary) => refreshes.push(summary)
        None => ()
      }
      updated.push(schedule)
    }
  }
  save_civic_salon_schedules(schedule_path, updated)
  if summaries.length() == 0 && refreshes.length() == 0 {
    "No civic communication-pattern schedules due at now_ms=\{now_ms}."
  } else if summaries.length() == 0 {
    "Refreshed \{refreshes.length()} civic communication-pattern projection(s): \{refreshes.join("; ")}"
  } else if refreshes.length() == 0 {
    "Ran \{summaries.length()} civic communication-pattern schedule(s): \{summaries.join("; ")}"
  } else {
    "Ran \{summaries.length()} civic communication-pattern schedule(s): \{summaries.join("; ")}; refreshed \{refreshes.length()} stale projection(s): \{refreshes.join("; ")}"
  }
}

///|
async fn run_due_civic_salon_round(
  schedule : CivicSalonSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
  reducer_mode : CivicSalonReductionMode,
) -> (CivicSalonSchedule, String) {
  match load_civic_salon_scenario_for_schedule(schedule, snapshot_path) {
    Some(scenario) =>
      run_civic_salon_scenario_round(
        scenario, schedule, snapshot_path, book_catalog_path, tick, now_ms, reducer_mode,
      )
    None => run_unsupported_civic_salon_round(schedule, now_ms)
  }
}

///|
async fn run_civic_salon_scenario_round(
  scenario : CivicSalonScenario,
  schedule : CivicSalonSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
  reducer_mode : CivicSalonReductionMode,
) -> (CivicSalonSchedule, String) {
  let participants = scenario.participants
  let round_id = civic_salon_round_id(schedule)
  let reduction = reduce_civic_salon_ideas(
    scenario,
    round_id~,
    round_number=schedule.round_count + 1,
    workspace_base=civic_salon_workspace_base(snapshot_path),
    mode=reducer_mode,
  )
  let ideas = reduction.ideas
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  let (decision, summary) = if reduction.status
    is @core.TaskExecutionStatus::Completed &&
    ideas.length() > 0 {
    (
      "review",
      materialize_civic_salon_scenario(
        scenario,
        ideas,
        book_catalog_path~,
        round_id~,
        round_number=schedule.round_count + 1,
        workspace_base=civic_salon_workspace_base(snapshot_path),
        reducer_summary=Some(reduction.summary),
      ),
    )
  } else {
    write_civic_salon_reducer_blocker(scenario, reduction, round_id)
    ("blocked", "Blocked \{scenario.title} \{round_id}: \{reduction.summary}")
  }
  let finished_ms = @env.now()
  let record = civic_salon_round_record(
    schedule, round_id, tick, now_ms, finished_ms, metrics, decision, summary,
  )
  append_civic_salon_round_record(
    default_civic_salon_run_ledger_path(schedule.id, snapshot_path~),
    record,
  )
  if decision == "review" {
    (
      complete_civic_salon_schedule(schedule, now_ms, round_id, summary),
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
fn run_unsupported_civic_salon_round(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
) -> (CivicSalonSchedule, String) {
  let summary = "Unsupported civic communication-pattern schedule `\{schedule.id}`; no round executed."
  let round_id = civic_salon_round_id(schedule)
  (
    {
      ..schedule,
      latest_round_id: round_id,
      latest_summary: summary,
      next_due_ms: now_ms + 300_000UL,
    },
    summary,
  )
}

///|
fn retry_civic_salon_schedule(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicSalonSchedule {
  {
    ..schedule,
    latest_round_id: round_id,
    latest_summary: summary,
    next_due_ms: now_ms + 300_000UL,
  }
}
