///|
pub fn civic_pattern_job_id() -> String {
  "run-civic-patterns"
}

///|
pub fn civic_pattern_job_kind() -> String {
  "civic-pattern"
}

///|
pub fn supervision_job_id() -> String {
  "supervise-live-runs"
}

///|
pub fn supervision_job_kind() -> String {
  "supervision"
}

///|
pub fn standing_goal_job_id() -> String {
  "dispatch-standing-goals"
}

///|
pub fn standing_goal_job_kind() -> String {
  "standing-goal"
}

///|
pub fn civic_service_job_id() -> String {
  "reconcile-civic-services"
}

///|
pub fn civic_service_job_kind() -> String {
  "civic-service"
}

///|
pub fn book_quality_job_id() -> String {
  "refresh-book-quality"
}

///|
pub fn book_quality_job_kind() -> String {
  "book-quality"
}

///|
pub fn book_quality_review_job_id() -> String {
  "review-book-quality"
}

///|
pub fn book_quality_review_job_kind() -> String {
  "book-quality-review"
}

///|
pub fn health_job_id() -> String {
  "refresh-health"
}

///|
pub fn health_job_kind() -> String {
  "health"
}

///|
pub fn projection_job_id() -> String {
  "project-ui-state"
}

///|
pub fn projection_job_kind() -> String {
  "projection"
}

///|
pub fn book_template_request_job_id() -> String {
  "process-book-template-requests"
}

///|
pub fn book_template_request_job_kind() -> String {
  "book-template-request"
}

///|
pub fn default_daemon_jobs() -> Array[ScheduledJob] {
  [
    {
      id: supervision_job_id(),
      kind: supervision_job_kind(),
      interval_seconds: 30,
    },
    {
      id: standing_goal_job_id(),
      kind: standing_goal_job_kind(),
      interval_seconds: 30,
    },
    {
      id: civic_pattern_job_id(),
      kind: civic_pattern_job_kind(),
      interval_seconds: 30,
    },
    {
      id: civic_service_job_id(),
      kind: civic_service_job_kind(),
      interval_seconds: 60,
    },
    {
      id: book_quality_job_id(),
      kind: book_quality_job_kind(),
      interval_seconds: 300,
    },
    {
      id: book_quality_review_job_id(),
      kind: book_quality_review_job_kind(),
      interval_seconds: 1800,
    },
    { id: health_job_id(), kind: health_job_kind(), interval_seconds: 60 },
    {
      id: projection_job_id(),
      kind: projection_job_kind(),
      interval_seconds: 60,
    },
    {
      id: book_template_request_job_id(),
      kind: book_template_request_job_kind(),
      interval_seconds: 30,
    },
  ]
}

///|
pub fn merge_default_daemon_jobs(
  jobs : Array[ScheduledJob],
) -> Array[ScheduledJob] {
  let merged : Array[ScheduledJob] = []
  for job in jobs {
    if !daemon_job_deprecated(job) &&
      !merged.any(fn(existing) { existing.id == job.id }) {
      merged.push(job)
    }
  }
  for job in default_daemon_jobs() {
    if !merged.any(fn(existing) { existing.id == job.id }) {
      merged.push(job)
    }
  }
  merged
}

///|
fn daemon_job_deprecated(job : ScheduledJob) -> Bool {
  retired_legacy_civic_communication_job(job)
}

///|
fn retired_legacy_civic_communication_job(job : ScheduledJob) -> Bool {
  job.id == "run-civic-salons" || job.kind == "civic-salon"
}

///|
pub fn scheduled_job_is_civic_pattern(job : ScheduledJob) -> Bool {
  job.kind == civic_pattern_job_kind()
}

///|
pub fn scheduled_job_is_supervision(job : ScheduledJob) -> Bool {
  job.kind == supervision_job_kind()
}

///|
pub fn scheduled_job_is_standing_goal(job : ScheduledJob) -> Bool {
  job.kind == standing_goal_job_kind()
}

///|
pub fn scheduled_job_is_civic_service(job : ScheduledJob) -> Bool {
  job.kind == civic_service_job_kind()
}

///|
pub fn scheduled_job_is_book_quality(job : ScheduledJob) -> Bool {
  job.kind == book_quality_job_kind()
}

///|
pub fn scheduled_job_is_book_quality_review(job : ScheduledJob) -> Bool {
  job.kind == book_quality_review_job_kind()
}

///|
pub fn scheduled_job_is_health(job : ScheduledJob) -> Bool {
  job.kind == health_job_kind()
}

///|
pub fn scheduled_job_is_projection(job : ScheduledJob) -> Bool {
  job.kind == projection_job_kind()
}

///|
pub fn scheduled_job_is_book_template_request(job : ScheduledJob) -> Bool {
  job.kind == book_template_request_job_kind()
}

///|
pub fn scheduled_job_runs_civic_communication(job : ScheduledJob) -> Bool {
  scheduled_job_is_civic_pattern(job)
}
