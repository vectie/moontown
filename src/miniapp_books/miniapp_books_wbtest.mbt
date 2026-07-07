///|
test "book binding exposes primary support books and private ledgers for editors" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let detail = miniapp_project_building_book_detail(
    snapshot,
    context.viewer,
    "private-lab",
    support_book_ids=["book-policy-hall"],
  ).unwrap()
  assert_eq(detail.building_id, "private-lab")
  assert_eq(detail.primary_book.id, "book-private-lab")
  assert_eq(detail.support_books.length(), 1)
  assert_true(detail.ledgers is Some(_))
  assert_true(detail.can_query)
  assert_true(detail.can_accept_memory)
}

///|
test "book detail hides private ledger ids for public viewers" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-b",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let detail = miniapp_project_building_book_detail(
    snapshot,
    context.viewer,
    "policy-hall",
  ).unwrap()
  assert_eq(
    detail.primary_book.summary,
    "Ask for policy checklists and routed review.",
  )
  assert_true(detail.ledgers is None)
  assert_true(detail.can_query)
  assert_true(!detail.can_accept_memory)
}

///|
test "building query records run against building book" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let before_book = miniapp_test_book(snapshot, "book-private-lab").unwrap()
  let change = miniapp_record_building_query(
    snapshot,
    context.viewer,
    {
      building_id: "private-lab",
      run_id: "run-private-lab-1",
      thread_id: "thread-private-lab-1",
      agent_id: None,
      question_summary: "Summarize this draft lab.",
    },
    now_ms=300UL,
  )
  assert_true(change.ok)
  assert_true(miniapp_test_has_run(change.snapshot, "run-private-lab-1"))
  let after_book = miniapp_test_book(change.snapshot, "book-private-lab").unwrap()
  assert_eq(
    after_book.pending_review_count,
    before_book.pending_review_count + 1,
  )
  assert_eq(
    miniapp_test_thread_message_count(change.snapshot, "thread-private-lab-1"),
    1,
  )
}

///|
test "accepted answer becomes book memory after review" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let queried = miniapp_record_building_query(
    snapshot,
    context.viewer,
    {
      building_id: "private-lab",
      run_id: "run-private-lab-2",
      thread_id: "thread-private-lab-2",
      agent_id: Some("agent-policy-guide"),
      question_summary: "Create a launch checklist.",
    },
    now_ms=300UL,
  )
  let before_book = miniapp_test_book(queried.snapshot, "book-private-lab").unwrap()
  let accepted = miniapp_accept_run_as_memory(
    queried.snapshot,
    context.viewer,
    {
      run_id: "run-private-lab-2",
      accepted_summary: "Launch checklist accepted for the private lab.",
    },
    now_ms=400UL,
  )
  assert_true(accepted.ok)
  let after_book = miniapp_test_book(accepted.snapshot, "book-private-lab").unwrap()
  assert_eq(
    after_book.accepted_memory_count,
    before_book.accepted_memory_count + 1,
  )
  assert_eq(
    after_book.pending_review_count,
    before_book.pending_review_count - 1,
  )
  assert_true(
    miniapp_test_run_status(accepted.snapshot, "run-private-lab-2") ==
    @miniapp_contracts.RunDone,
  )
}

///|
test "invisible building cannot expose book detail or record query" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-b",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  assert_true(
    miniapp_project_building_book_detail(
      snapshot,
      context.viewer,
      "private-lab",
    )
    is None,
  )
  let rejected = miniapp_record_building_query(
    snapshot,
    context.viewer,
    {
      building_id: "private-lab",
      run_id: "run-rejected",
      thread_id: "thread-rejected",
      agent_id: None,
      question_summary: "Should not be visible.",
    },
    now_ms=300UL,
  )
  assert_true(!rejected.ok)
  assert_true(!miniapp_test_has_run(rejected.snapshot, "run-rejected"))
}

///|
fn miniapp_test_book(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  book_id : String,
) -> @miniapp_contracts.MiniappBookSummary? {
  for book in snapshot.books {
    if book.id == book_id {
      return Some(book)
    }
  }
  None
}

///|
fn miniapp_test_has_run(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  run_id : String,
) -> Bool {
  for run in snapshot.runs {
    if run.id == run_id {
      return true
    }
  }
  false
}

///|
fn miniapp_test_run_status(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  run_id : String,
) -> @miniapp_contracts.MiniappRunStatus {
  for run in snapshot.runs {
    if run.id == run_id {
      return run.status
    }
  }
  @miniapp_contracts.RunFailed
}

///|
fn miniapp_test_thread_message_count(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  thread_id : String,
) -> Int {
  for thread in snapshot.threads {
    if thread.id == thread_id {
      return thread.message_count
    }
  }
  0
}
