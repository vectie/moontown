///|
pub async fn run_due_civic_salons(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  tick? : Int = 0,
  now_ms? : UInt64 = @env.now(),
  reducer_mode? : CivicSalonReductionMode = MoonClawReducer,
  run_inline? : Bool = moontown_moonclaw_inline_enabled(),
) -> String {
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
  let summaries : Array[String] = []
  let refreshes : Array[String] = []
  for schedule in schedules {
    if civic_salon_is_due(schedule, now_ms) {
      persist_civic_salon_schedule(
        schedule_path,
        schedule.id,
        claim_civic_salon_schedule(schedule, now_ms),
      )
      let (next, summary) = run_due_civic_salon_round(
        schedule, snapshot_path, book_catalog_path, tick, now_ms, reducer_mode, run_inline,
      )
      persist_civic_salon_schedule(schedule_path, schedule.id, next)
      summaries.push(summary)
    } else {
      match
        refresh_or_reconcile_civic_salon_schedule(
          schedule, schedule_path, snapshot_path, book_catalog_path, tick, now_ms,
        ) {
        Some(summary) => refreshes.push(summary)
        None => ()
      }
    }
  }
  civic_salon_due_run_summary(summaries, refreshes, now_ms)
}
