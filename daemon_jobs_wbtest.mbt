///|
test "daemon scheduled job event records only completed civic salon runs" {
  let job = @scheduler.default_daemon_jobs().get(2).unwrap()
  match
    daemon_scheduled_job_event_for_summary(
      job, 7, "Ran 1 civic salon(s): embodied-robotics",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-run-civic-salons-7")
      assert_eq(event.kind, "civic-salon")
      assert_true(event.detail.contains("Ran 1 civic salon"))
    }
    None => fail("expected civic salon event")
  }
  match
    daemon_scheduled_job_event_for_summary(
      job, 7, "No civic salons due at now_ms=1.",
    ) {
    Some(_) => fail("no-change salon tick should not record activity")
    None => ()
  }
}

///|
test "daemon scheduled job event ignores non-civic jobs" {
  let job = @scheduler.default_daemon_jobs().get(3).unwrap()
  match daemon_scheduled_job_event_for_summary(job, 3, "Ran health check") {
    Some(_) => fail("generic health job should not use civic salon event shape")
    None => ()
  }
}
