///|
pub fn default_daemon_jobs() -> Array[ScheduledJob] {
  [
    { id: "supervise-live-runs", kind: "supervision", interval_seconds: 30 },
    {
      id: "dispatch-standing-goals",
      kind: "standing-goal",
      interval_seconds: 30,
    },
    { id: "run-civic-patterns", kind: "civic-pattern", interval_seconds: 30 },
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
  job.id == "run-civic-salons" || job.kind == "civic-salon"
}
