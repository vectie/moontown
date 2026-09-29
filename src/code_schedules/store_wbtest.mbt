///|
async test "Code schedule intent survives restart and cannot be reserved twice" {
  let root = @fsx.mkdtemp("/tmp/moontown-code-schedule-XXXXXX")
  let path = root + "/schedules/state.json"
  let schedule = CodeSchedule::new(
    id="nightly",
    book_id="book-a",
    book_root="/suite/books/a",
    session_id="code-nightly",
    prompt="Review changes",
    model="provider/model",
    interval_seconds=60,
    now=1000L,
  ).unwrap()
  let created = create_code_schedule(schedule, path~)
  assert_eq(created.revision, 1)
  assert_true(reserve_due_code_schedule(1059L, path~) is None)
  guard reserve_due_code_schedule(1060L, path~) is Some(intent) else {
    fail("expected persisted dispatch intent")
  }
  assert_eq(intent.command_id, "code-schedule-nightly-1060")
  assert_true(reserve_due_code_schedule(1061L, path~) is None)
  let reloaded = load_code_schedule_state(path~)
  assert_eq(reloaded.schedules[0].pending_command_id, intent.command_id)
  assert_eq(reloaded.schedules[0].last_status, "dispatching")
  assert_true(
    record_code_schedule_uncertain("nightly", intent.command_id, path~),
  )
  assert_true(reserve_due_code_schedule(2000L, path~) is None)
  assert_true(
    record_code_schedule_acceptance("nightly", intent.command_id, path~),
  )
  assert_true(
    record_code_schedule_terminal(
      "nightly",
      intent.command_id,
      "done",
      1100L,
      path~,
    ),
  )
  let completed = load_code_schedule_state(path~)
  assert_eq(completed.schedules[0].last_status, "done")
  assert_eq(completed.schedules[0].next_due_at, 1160L)
  assert_true(set_code_schedule_enabled("nightly", false, 1150L, path~))
  assert_true(reserve_due_code_schedule(1160L, path~) is None)
  assert_true(set_code_schedule_enabled("nightly", true, 1200L, path~))
  assert_eq(load_code_schedule_state(path~).schedules[0].next_due_at, 1200L)
  assert_true(reserve_due_code_schedule(1159L, path~) is None)
  assert_true(reserve_due_code_schedule(1200L, path~) is Some(_))
}

///|
async test "Code schedule store rejects duplicate session identities" {
  let root = @fsx.mkdtemp("/tmp/moontown-code-schedule-XXXXXX")
  let path = root + "/schedules/state.json"
  let first = CodeSchedule::new(
    id="first",
    book_id="book-a",
    book_root="/suite/books/a",
    session_id="shared-session",
    prompt="Review changes",
    model="provider/model",
    interval_seconds=60,
    now=0L,
  ).unwrap()
  ignore(create_code_schedule(first, path~))
  let second = CodeSchedule::new(
    id="second",
    book_id="book-a",
    book_root="/suite/books/a",
    session_id="shared-session",
    prompt="Run tests",
    model="provider/model",
    interval_seconds=60,
    now=0L,
  ).unwrap()
  let rejected = try {
    ignore(create_code_schedule(second, path~))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_eq(load_code_schedule_state(path~).schedules.length(), 1)
}

///|
async test "Code schedule dispatcher rotates a bounded batch of pending runs" {
  let root = @fsx.mkdtemp("/tmp/moontown-code-schedule-XXXXXX")
  let path = root + "/schedules/state.json"
  for index in 0..<5 {
    let id = "review-\{index}"
    let schedule = CodeSchedule::new(
      id~,
      book_id="book-a",
      book_root="/suite/books/a",
      session_id="code-schedule-\{id}",
      prompt="Review code",
      model="moongate/example",
      interval_seconds=60,
      now=0L,
    ).unwrap()
    ignore(create_code_schedule(schedule, path~))
    assert_true(reserve_due_code_schedule(60L, path~) is Some(_))
  }
  let first = pending_code_schedule_intents(path~)
  assert_eq(first.length(), 4)
  for intent in first {
    assert_true(
      record_code_schedule_attempt(
        intent.schedule_id,
        intent.command_id,
        60L,
        path~,
      ),
    )
  }
  let next = pending_code_schedule_intents(path~)
  assert_eq(next.length(), 4)
  assert_eq(next[0].schedule_id, "review-4")
}
