///|
test "daemon scheduled job event records only completed civic pattern runs" {
  let job = @scheduler.default_daemon_jobs().get(2).unwrap()
  match
    daemon_scheduled_job_event_for_summary(
      job, 7, "Ran 1 civic communication-pattern schedule(s): embodied-robotics",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-run-civic-patterns-7")
      assert_eq(event.kind, @scheduler.civic_pattern_job_kind())
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
test "daemon scheduled jobs honor real interval ticks" {
  let every_tick = @scheduler.default_daemon_jobs().get(0).unwrap()
  let every_two_ticks = @scheduler.default_daemon_jobs().get(3).unwrap()
  let every_ten_ticks = @scheduler.default_daemon_jobs().get(4).unwrap()
  let every_sixty_ticks = @scheduler.default_daemon_jobs().get(5).unwrap()
  assert_true(daemon_scheduled_job_due(every_tick, 7))
  assert_true(!daemon_scheduled_job_due(every_two_ticks, 7))
  assert_true(daemon_scheduled_job_due(every_two_ticks, 8))
  assert_true(!daemon_scheduled_job_due(every_ten_ticks, 9))
  assert_true(daemon_scheduled_job_due(every_ten_ticks, 10))
  assert_true(!daemon_scheduled_job_due(every_sixty_ticks, 59))
  assert_true(daemon_scheduled_job_due(every_sixty_ticks, 60))
}

///|
test "daemon scheduled job event ignores non-civic jobs" {
  let job = @scheduler.default_daemon_jobs().get(6).unwrap()
  match daemon_scheduled_job_event_for_summary(job, 3, "Ran health check") {
    Some(_) =>
      fail("generic health job should not use civic pattern event shape")
    None => ()
  }
}

///|
test "daemon scheduled job records book quality refresh activity" {
  let job = @scheduler.default_daemon_jobs().get(4).unwrap()
  match
    daemon_scheduled_job_event_for_summary(
      job, 11, "Wrote book management audit for 21 registered book(s) to .moontown/book-quality/audit.json and .moontown/book-quality/audit.md; weakest_structural=research-embodied-robotics(55). Semantic quality scores require AI review results.",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-refresh-book-quality-11")
      assert_eq(event.kind, @scheduler.book_quality_job_kind())
    }
    None => fail("expected book quality refresh event")
  }
}

///|
test "daemon scheduled job records dispatched book quality ai review" {
  let job = @scheduler.default_daemon_jobs().get(5).unwrap()
  match
    daemon_scheduled_job_event_for_summary(
      job, 12, "Dispatched AI semantic book-quality review for `research-opc`. Imported proposal.",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-review-book-quality-12")
      assert_eq(event.kind, @scheduler.book_quality_review_job_kind())
    }
    None => fail("expected book quality AI review event")
  }
  match
    daemon_scheduled_job_event_for_summary(
      job, 13, "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=1",
    ) {
    Some(_) => fail("active review should not be recorded as new activity")
    None => ()
  }
}

///|
test "daemon scheduled job records civic service reconciliation activity" {
  let job = @scheduler.default_daemon_jobs().get(3).unwrap()
  match
    daemon_scheduled_job_event_for_summary(
      job, 9, "Reconciled 2 Wenyu civic service result(s); skipped=9; blocked=0.",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-reconcile-civic-services-9")
      assert_eq(event.kind, @scheduler.civic_service_job_kind())
    }
    None => fail("expected civic service reconciliation event")
  }
  match
    daemon_scheduled_job_event_for_summary(
      job, 10, "Reconciled 0 Wenyu civic service result(s); skipped=11; blocked=0.",
    ) {
    Some(_) => fail("no-change civic service reconciliation should stay quiet")
    None => ()
  }
}

///|
test "daemon scheduled job records processed book template request activity" {
  let job = book_template_request_job_for_test()
  match
    daemon_scheduled_job_event_for_summary(
      job, 14, "Processed 1 book template request(s); pending=0 installed=1 failed=0.",
    ) {
    Some(event) => {
      assert_eq(event.id, "event-process-book-template-requests-14")
      assert_eq(event.kind, @scheduler.book_template_request_job_kind())
    }
    None => fail("expected book template request activity event")
  }
  match
    daemon_scheduled_job_event_for_summary(
      job, 15, "Processed 0 book template request(s); pending=0 installed=0 failed=0.",
    ) {
    Some(_) => fail("empty request inbox should stay quiet")
    None => ()
  }
}

///|
fn book_template_request_job_for_test() -> @scheduler.ScheduledJob {
  let jobs = @scheduler.default_daemon_jobs()
  for job in jobs {
    if @scheduler.scheduled_job_is_book_template_request(job) {
      return job
    }
  }
  jobs.get(0).unwrap()
}
