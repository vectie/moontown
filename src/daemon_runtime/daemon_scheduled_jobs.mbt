///|
pub async fn run_daemon_scheduled_jobs(
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
  if @scheduler.scheduled_job_runs_civic_communication(job) {
    Some(
      @civic_runtime.run_due_civic_communication_patterns(
        snapshot_path~,
        book_catalog_path~,
        tick~,
        run_inline=false,
      ),
    )
  } else if @scheduler.scheduled_job_is_civic_service(job) {
    Some(
      @civic_runtime.reconcile_wenyu_civic_service_results(book_catalog_path~),
    )
  } else if @scheduler.scheduled_job_is_book_quality(job) {
    Some(
      @book_quality_runtime.write_book_quality_audit(
        book_catalog_path~,
        snapshot_path~,
      ),
    )
  } else if @scheduler.scheduled_job_is_book_quality_review(job) {
    Some(run_book_quality_review_cycle(book_catalog_path, snapshot_path))
  } else if @scheduler.scheduled_job_is_book_template_request(job) {
    Some(
      @book_templates_runtime.process_book_template_requests(
        request_path=@book_templates.request_path_for_snapshot(snapshot_path),
        book_catalog_path~,
        tick~,
      ),
    )
  } else {
    None
  }
}

///|
async fn run_book_quality_review_cycle(
  book_catalog_path : String,
  snapshot_path : String,
) -> String {
  let bridge = @book_quality_runtime.reconcile_book_quality_repair_bridge(
    book_catalog_path~,
    snapshot_path~,
  )
  let dispatch = @book_quality_runtime.dispatch_next_book_quality_ai_review(
    book_catalog_path~,
    snapshot_path~,
    run_inline=false,
  )
  "\{bridge} \{dispatch}"
}
