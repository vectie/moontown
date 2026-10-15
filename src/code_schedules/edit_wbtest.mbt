///|
async test "calendar schedule edits persist and one-off work disables after completion" {
  let root = @fsx.mkdtemp("/tmp/moontown-calendar-XXXXXX")
  let path = root + "/state.json"
  let schedule = CodeSchedule::new(
    id="review",
    book_id="book",
    book_root="/suite/book",
    session_id="code-review",
    prompt="Review changes",
    model="provider/model",
    interval_seconds=3600,
    now=1000L,
  ).unwrap()
  ignore(create_code_schedule(schedule, path~))
  let changed = edit_code_schedule(
    "review",
    title="Review before meeting",
    prompt="Review the latest changes",
    model="provider/model",
    interval_seconds=86400,
    next_due_at=2000L,
    repeat=false,
    path~,
  )
  assert_eq(changed.schedules[0].title, Some("Review before meeting"))
  assert_true(reserve_due_code_schedule(1999L, path~) is None)
  guard reserve_due_code_schedule(2000L, path~) is Some(intent) else {
    fail("expected due task")
  }
  assert_true(
    record_code_schedule_terminal(
      "review",
      intent.command_id,
      "done",
      2100L,
      path~,
    ),
  )
  assert_false(load_code_schedule_state(path~).schedules[0].enabled)
  assert_true(reserve_due_code_schedule(100000L, path~) is None)
  ignore(run_code_schedule_now("review", 100000L, path~))
  assert_true(reserve_due_code_schedule(100000L, path~) is Some(_))
}

///|
async test "removing a schedule keeps other schedules and prevents future dispatch" {
  let root = @fsx.mkdtemp("/tmp/moontown-calendar-XXXXXX")
  let path = root + "/state.json"
  ignore(
    create_code_schedule(
      CodeSchedule::new(
        id="review",
        book_id="book",
        book_root="/suite/book",
        session_id="code-review",
        prompt="Review changes",
        model="provider/model",
        interval_seconds=3600,
        now=1000L,
      ).unwrap(),
      path~,
    ),
  )
  assert_eq(delete_code_schedule("review", path~).schedules.length(), 0)
  assert_true(reserve_due_code_schedule(5000L, path~) is None)
}

///|
async test "calendar weekdays skip weekends and daily schedules keep wall time across DST" {
  let zone = code_schedule_zone("America/New_York")
  let friday = @time.date_time(2026, 10, 30, hour=9, zone~).to_unix_second()
  let schedule = CodeSchedule::new(
    id="daily",
    book_id="book",
    book_root="/suite/book",
    session_id="code-daily",
    prompt="Review changes",
    model="provider/model",
    interval_seconds=86400,
    now=0L,
  ).unwrap()
  let weekdays = {
    ..schedule,
    next_due_at: friday,
    recurrence: Some("weekdays"),
    timezone: Some("America/New_York"),
  }
  let monday = code_schedule_calendar_next(weekdays, friday + 60L, zone)
  let expected = @time.date_time(2026, 11, 2, hour=9, zone~).to_unix_second()
  assert_eq(monday, expected)
  assert_eq(monday - friday, 3L * 86400L + 3600L)
  let daily = { ..weekdays, recurrence: Some("daily"), }
  let saturday = code_schedule_calendar_next(daily, friday + 60L, zone)
  let sunday = code_schedule_calendar_next(
    { ..daily, next_due_at: saturday, },
    saturday + 60L,
    zone,
  )
  assert_eq(@time.unix(sunday, zone~).hour(), 9)
  assert_eq(sunday - saturday, 90000L)
  let manual_run = {
    ..weekdays,
    calendar_anchor_at: Some(friday),
    next_due_at: friday + 7200L,
  }
  assert_eq(
    code_schedule_calendar_next(manual_run, friday + 7260L, zone),
    expected,
  )
}
