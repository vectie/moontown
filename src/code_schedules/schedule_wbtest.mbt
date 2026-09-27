///|
test "Code schedule persists one command identity through uncertain dispatch" {
  let schedule = CodeSchedule::new(
    id="daily-review",
    book_id="book-a",
    book_root="/suite/books/a",
    session_id="code-daily-review",
    prompt="Review changed code and report findings",
    model="provider/model",
    interval_seconds=3600,
    now=1000L,
  ).unwrap()
  assert_true(schedule.prepare_due(4599L) is None)
  guard schedule.prepare_due(4600L) is Some((intent_saved, intent)) else {
    fail("expected due Code schedule")
  }
  assert_eq(intent.command_id, "code-schedule-daily-review-4600")
  assert_eq(intent.session_id, schedule.session_id)
  assert_true(intent_saved.prepare_due(4700L) is None)
  guard intent_saved.mark_uncertain(intent.command_id) is Some(uncertain) else {
    fail("expected uncertain dispatch")
  }
  assert_true(uncertain.prepare_due(8000L) is None)
  guard uncertain.mark_accepted(intent.command_id) is Some(accepted) else {
    fail("expected acceptance of original identity")
  }
  assert_eq(accepted.last_status, "accepted")
  guard accepted.mark_terminal(intent.command_id, "done", 5000L) is Some(done) else {
    fail("expected terminal Code run")
  }
  assert_eq(done.next_due_at, 8600L)
  assert_eq(done.pending_command_id, "")
  assert_true(done.mark_terminal(intent.command_id, "done", 5001L) is None)
}

///|
test "paused Code schedule retains an unresolved run and resumes safely" {
  let schedule = CodeSchedule::new(
    id="nightly-check",
    book_id="book-b",
    book_root="/suite/books/b",
    session_id="code-nightly-check",
    prompt="Run focused tests",
    model="provider/model",
    interval_seconds=60,
    now=0L,
  ).unwrap()
  guard schedule.prepare_due(60L) is Some((pending, intent)) else {
    fail("expected due run")
  }
  let paused = pending.pause()
  assert_true(paused.prepare_due(120L) is None)
  let resumed = paused.reactivate(120L)
  assert_true(resumed.prepare_due(120L) is None)
  guard resumed.mark_terminal(intent.command_id, "failed", 125L) is Some(failed) else {
    fail("expected failed run to remain visible")
  }
  assert_eq(failed.last_status, "failed")
  assert_eq(failed.next_due_at, 185L)
  assert_true(failed.prepare_due(184L) is None)
  assert_true(failed.prepare_due(185L) is Some(_))
}

///|
test "Code schedules reject invalid identity cadence and prompt" {
  assert_true(
    CodeSchedule::new(
      id="../bad",
      book_id="book",
      book_root="/suite/books/book",
      session_id="session",
      prompt="Review code",
      model="provider/model",
      interval_seconds=60,
      now=0L,
    )
    is Err(_),
  )
  assert_true(
    CodeSchedule::new(
      id="valid",
      book_id="book",
      book_root="/suite/books/book",
      session_id="session",
      prompt="  ",
      model="provider/model",
      interval_seconds=59,
      now=0L,
    )
    is Err(_),
  )
}

///|
test "pending Code run reports actionable control and MoonBook blockers" {
  let schedule = CodeSchedule::new(
    id="review",
    book_id="book",
    book_root="/suite/books/book",
    session_id="code-schedule-review",
    prompt="Review code",
    model="moongate/example",
    interval_seconds=60,
    now=0L,
  ).unwrap()
  guard schedule.prepare_due(60L) is Some((pending, intent)) else {
    fail("expected due run")
  }
  guard pending.mark_waiting(intent.command_id, "waiting-control")
    is Some(waiting) else {
    fail("expected control blocker")
  }
  assert_eq(waiting.last_status, "waiting-control")
  guard waiting.mark_waiting(intent.command_id, "book-unavailable")
    is Some(book_missing) else {
    fail("expected MoonBook blocker")
  }
  assert_eq(book_missing.pending_command_id, intent.command_id)
  assert_true(book_missing.mark_waiting(intent.command_id, "done") is None)
}

///|
test "Code schedule state can read records saved before attempt timestamps" {
  let legacy : Json = {
    "id": "nightly",
    "book_id": "book",
    "book_root": "/suite/books/book",
    "session_id": "code-schedule-nightly",
    "prompt": "Review code",
    "model": "moongate/example",
    "interval_seconds": 60,
    "enabled": true,
    "next_due_at": "60",
    "pending_command_id": "",
    "last_command_id": "",
    "last_status": "never-run",
    "last_finished_at": "0",
  }
  let schedule : CodeSchedule = @json.from_json(legacy)
  assert_true(schedule.last_attempt_at is None)
}
