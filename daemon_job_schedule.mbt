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
