///|
test "daemon scheduled job event records only completed civic pattern runs" {
  let job = @scheduler.default_daemon_jobs().get(2).unwrap()
  match
    daemon_scheduled_job_event_for_summary(
      job, 7, "Ran 1 civic communication-pattern schedule(s): embodied-robotics",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-run-civic-patterns-7")
      assert_eq(event.kind, "civic-pattern")
      assert_true(event.detail.contains("Ran 1 civic communication-pattern"))
    }
    None => fail("expected civic pattern event")
  }
  match
    daemon_scheduled_job_event_for_summary(
      job, 7, "No civic communication-pattern schedules due at now_ms=1.",
    ) {
    Some(_) => fail("no-change pattern tick should not record activity")
    None => ()
  }
}

///|
test "daemon scheduled job event ignores non-civic jobs" {
  let job = @scheduler.default_daemon_jobs().get(3).unwrap()
  match daemon_scheduled_job_event_for_summary(job, 3, "Ran health check") {
    Some(_) =>
      fail("generic health job should not use civic pattern event shape")
    None => ()
  }
}
