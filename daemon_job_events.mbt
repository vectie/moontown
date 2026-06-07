///|
fn daemon_scheduled_job_event_for_summary(
  job : @scheduler.ScheduledJob,
  tick : Int,
  summary : String,
) -> @core.TownEvent? {
  if (job.kind == "civic-pattern" || job.kind == "civic-salon") &&
    summary.has_prefix("Ran ") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if job.kind == "civic-service" &&
    summary.has_prefix("Reconciled ") &&
    !summary.has_prefix("Reconciled 0 ") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if job.kind == "book-quality" &&
    summary.has_prefix("Wrote book management audit") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if job.kind == "book-quality-review" &&
    (
      summary.contains("Dispatched AI semantic book-quality review") ||
      summary.has_prefix("Bridged ")
    ) {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if job.kind == "book-template-request" &&
    summary.has_prefix("Processed ") &&
    !summary.has_prefix("Processed 0 ") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else {
    None
  }
}

///|
fn daemon_scheduled_job_event(
  job : @scheduler.ScheduledJob,
  tick : Int,
  summary : String,
) -> @core.TownEvent {
  @core.TownEvent::new(
    id="event-\{job.id}-\{tick}",
    kind=job.kind,
    detail=summary,
  )
}
