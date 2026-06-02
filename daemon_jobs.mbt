///|
async fn run_daemon_scheduled_jobs(
  state : @core.TownState,
  jobs : Array[@scheduler.ScheduledJob],
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  log_path : String,
) -> Unit {
  for job in @scheduler.merge_default_daemon_jobs(jobs) {
    if !daemon_scheduled_job_due(job, tick) {
      continue
    }
    append_daemon_log(
      log_path,
      "tick phase=scheduled-job-start sequence=\{tick} job=\{job.id} kind=\{job.kind}",
    )
    match
      run_daemon_scheduled_job(job, snapshot_path, book_catalog_path, tick) {
      Some(summary) => {
        append_daemon_log(
          log_path,
          "tick phase=scheduled-job-done sequence=\{tick} job=\{job.id} kind=\{job.kind}",
        )
        match daemon_scheduled_job_event_for_summary(job, tick, summary) {
          Some(event) => state.record_event(event)
          None => ()
        }
      }
      None =>
        append_daemon_log(
          log_path,
          "tick phase=scheduled-job-skip sequence=\{tick} job=\{job.id} kind=\{job.kind}",
        )
    }
  }
}

///|
fn daemon_scheduled_job_due(job : @scheduler.ScheduledJob, tick : Int) -> Bool {
  let interval_ticks = daemon_scheduled_job_interval_ticks(job)
  tick % interval_ticks == 0
}

///|
fn daemon_scheduled_job_interval_ticks(job : @scheduler.ScheduledJob) -> Int {
  let interval = if job.interval_seconds <= 0 {
    30
  } else {
    job.interval_seconds
  }
  let ticks = (interval + 29) / 30
  if ticks < 1 {
    1
  } else {
    ticks
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
    "civic-pattern" =>
      Some(
        run_due_civic_salons(
          snapshot_path~,
          book_catalog_path~,
          tick~,
          run_inline=false,
        ),
      )
    "civic-salon" =>
      Some(
        run_due_civic_salons(
          snapshot_path~,
          book_catalog_path~,
          tick~,
          run_inline=false,
        ),
      )
    "civic-service" =>
      Some(reconcile_wenyu_civic_service_results(book_catalog_path~))
    "book-quality" =>
      Some(write_book_quality_audit(book_catalog_path~, snapshot_path~))
    "book-quality-review" =>
      Some(run_book_quality_review_cycle(book_catalog_path, snapshot_path))
    "book-template-request" =>
      Some(
        process_book_template_requests(
          request_path=default_book_template_request_path(snapshot_path~),
          book_catalog_path~,
          tick~,
        ),
      )
    _ => None
  }
}

///|
async fn run_book_quality_review_cycle(
  book_catalog_path : String,
  snapshot_path : String,
) -> String {
  let bridge = reconcile_book_quality_repair_bridge(
    book_catalog_path~,
    snapshot_path~,
  )
  let dispatch = dispatch_next_book_quality_ai_review(
    book_catalog_path~,
    snapshot_path~,
    run_inline=false,
  )
  "\{bridge} \{dispatch}"
}

///|
fn daemon_scheduled_job_event_for_summary(
  job : @scheduler.ScheduledJob,
  tick : Int,
  summary : String,
) -> @core.TownEvent? {
  if (job.kind == "civic-pattern" || job.kind == "civic-salon") &&
    summary.has_prefix("Ran ") {
    Some(
      @core.TownEvent::new(
        id="event-\{job.id}-\{tick}",
        kind=job.kind,
        detail=summary,
      ),
    )
  } else if job.kind == "civic-service" &&
    summary.has_prefix("Reconciled ") &&
    !summary.has_prefix("Reconciled 0 ") {
    Some(
      @core.TownEvent::new(
        id="event-\{job.id}-\{tick}",
        kind=job.kind,
        detail=summary,
      ),
    )
  } else if job.kind == "book-quality" &&
    summary.has_prefix("Wrote book management audit") {
    Some(
      @core.TownEvent::new(
        id="event-\{job.id}-\{tick}",
        kind=job.kind,
        detail=summary,
      ),
    )
  } else if job.kind == "book-quality-review" &&
    (
      summary.contains("Dispatched AI semantic book-quality review") ||
      summary.has_prefix("Bridged ")
    ) {
    Some(
      @core.TownEvent::new(
        id="event-\{job.id}-\{tick}",
        kind=job.kind,
        detail=summary,
      ),
    )
  } else if job.kind == "book-template-request" &&
    summary.has_prefix("Processed ") &&
    !summary.has_prefix("Processed 0 ") {
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
