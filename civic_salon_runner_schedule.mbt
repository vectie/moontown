///|
async fn persist_civic_salon_schedule(
  schedule_path : String,
  schedule_id : String,
  replacement : CivicSalonSchedule,
) -> Unit {
  save_civic_salon_schedules(
    schedule_path,
    replace_civic_salon_schedule(
      load_or_create_civic_salon_schedules(path=schedule_path),
      schedule_id,
      replacement,
    ),
  )
}

///|
fn civic_salon_due_run_summary(
  summaries : Array[String],
  refreshes : Array[String],
  now_ms : UInt64,
) -> String {
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
fn claim_civic_salon_schedule(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
) -> CivicSalonSchedule {
  {
    ..schedule,
    latest_round_id: civic_salon_round_id(schedule),
    latest_summary: "Running civic communication-pattern round; schedule claimed before worker launch.",
    next_due_ms: now_ms + 300_000UL,
  }
}

///|
fn replace_civic_salon_schedule(
  schedules : Array[CivicSalonSchedule],
  target_id : String,
  replacement : CivicSalonSchedule,
) -> Array[CivicSalonSchedule] {
  schedules.map(fn(schedule) {
    if schedule.id == target_id {
      replacement
    } else {
      schedule
    }
  })
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

///|
fn civic_salon_summary_is_active(summary : String) -> Bool {
  summary.has_prefix("Running ") ||
  summary.contains("MoonClaw reducer is still active")
}
