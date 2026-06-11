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
          request_path=@book_templates.request_path_for_snapshot(snapshot_path),
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
