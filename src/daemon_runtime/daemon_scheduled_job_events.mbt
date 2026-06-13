///|
fn daemon_scheduled_job_event_for_summary(
  job : @scheduler.ScheduledJob,
  tick : Int,
  summary : String,
) -> @core.TownEvent? {
  if @scheduler.scheduled_job_runs_civic_communication(job) &&
    summary.has_prefix("Ran ") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if @scheduler.scheduled_job_is_civic_service(job) &&
    summary.has_prefix("Reconciled ") &&
    !summary.has_prefix("Reconciled 0 ") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if @scheduler.scheduled_job_is_book_quality(job) &&
    summary.has_prefix("Wrote book management audit") {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if @scheduler.scheduled_job_is_book_quality_review(job) &&
    (
      summary.contains("Dispatched AI semantic book-quality review") ||
      summary.has_prefix("Queued ") ||
      summary.has_prefix("Refreshed ")
    ) {
    Some(daemon_scheduled_job_event(job, tick, summary))
  } else if @scheduler.scheduled_job_is_book_template_request(job) &&
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
