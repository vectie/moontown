///|
async fn run_daemon_scheduled_jobs(
  state : @core.TownState,
  jobs : Array[@scheduler.ScheduledJob],
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
) -> Unit {
  for job in @scheduler.merge_default_daemon_jobs(jobs) {
    match
      run_daemon_scheduled_job(job, snapshot_path, book_catalog_path, tick) {
      Some(summary) =>
        match daemon_scheduled_job_event_for_summary(job, tick, summary) {
          Some(event) => state.record_event(event)
          None => ()
        }
      None => ()
    }
  }
}

///|
async fn run_daemon_scheduled_job(
  job : @scheduler.ScheduledJob,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
) -> String? {
  match job.kind {
    "civic-salon" =>
      Some(run_due_civic_salons(snapshot_path~, book_catalog_path~, tick~))
    _ => None
  }
}

///|
fn daemon_scheduled_job_event_for_summary(
  job : @scheduler.ScheduledJob,
  tick : Int,
  summary : String,
) -> @core.TownEvent? {
  if job.kind == "civic-salon" && summary.has_prefix("Ran ") {
    Some(
      @core.TownEvent::new(
        id="event-\{job.id}-\{tick}",
        kind=job.kind,
        detail=summary,
      ),
    )
  } else {
    None
  }
}
