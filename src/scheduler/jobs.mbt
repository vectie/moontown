///|
pub fn civic_pattern_job_id() -> String {
  "run-civic-patterns"
}

///|
pub fn civic_pattern_job_kind() -> String {
  "civic-pattern"
}

///|
pub fn legacy_civic_salon_job_id() -> String {
  "run-civic-salons"
}

///|
pub fn legacy_civic_salon_job_kind() -> String {
  "civic-salon"
}

///|
pub fn default_daemon_jobs() -> Array[ScheduledJob] {
  [
    { id: "supervise-live-runs", kind: "supervision", interval_seconds: 30 },
    {
      id: "dispatch-standing-goals",
      kind: "standing-goal",
      interval_seconds: 30,
    },
    {
      id: civic_pattern_job_id(),
      kind: civic_pattern_job_kind(),
      interval_seconds: 30,
    },
    {
      id: "reconcile-civic-services",
      kind: "civic-service",
      interval_seconds: 60,
    },
    { id: "refresh-book-quality", kind: "book-quality", interval_seconds: 300 },
    {
      id: "review-book-quality",
      kind: "book-quality-review",
      interval_seconds: 1800,
    },
    { id: "refresh-health", kind: "health", interval_seconds: 60 },
    { id: "project-ui-state", kind: "projection", interval_seconds: 60 },
    {
      id: "process-book-template-requests",
      kind: "book-template-request",
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
  scheduled_job_is_legacy_civic_salon(job)
}

///|
pub fn scheduled_job_is_civic_pattern(job : ScheduledJob) -> Bool {
  job.kind == civic_pattern_job_kind()
}

///|
pub fn scheduled_job_is_legacy_civic_salon(job : ScheduledJob) -> Bool {
  job.id == legacy_civic_salon_job_id() ||
  job.kind == legacy_civic_salon_job_kind()
}

///|
pub fn scheduled_job_runs_civic_communication(job : ScheduledJob) -> Bool {
  scheduled_job_is_civic_pattern(job) ||
  scheduled_job_is_legacy_civic_salon(job)
}
