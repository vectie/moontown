///|
fn wenyu_review_supervision_fixture() -> (
  @core.TownState,
  @moonbook.BookCatalogEntry,
  @core.TaskExecutionRecord,
) {
  let state = @core.empty_state(
    @core.TownConfig::new(id="human-review", name="Human review"),
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="book",
    name="Book",
    purpose="Synthetic",
    workspace_root="/synthetic/book",
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="exact-task",
    book_id="book",
    packet_id="exact-work",
    packet_path="/synthetic/launch",
    status=ReviewQueued,
    summary="Book review pending",
    output_contract="wenyu.build.native-result.v1",
    result_decision="native-persisted-review",
    requires_review=true,
    next_retry_tick=None,
  )
  replace_execution_task_and_worker(state, execution)
  (state, entry, execution)
}

///|
async test "native human review save reload and repeat preserves acceptance pending and one bound event" {
  let (state, entry, execution) = wenyu_review_supervision_fixture()
  let approved = copy_execution_with(
    execution,
    status=AwaitingAcceptance,
    summary="Book review approved; exact-work; original-task and goal acceptance remain unevaluated",
    result_decision="native-book-review-approved",
    requires_review=false,
  )
  reconcile_wenyu_review_execution(state, entry, execution, 3, readback=async fn(
    _,
    _,
    _,
  ) {
    approved
  })
  assert_eq(state.executions[0], approved)
  assert_eq(state.tasks[0].status, Blocked)
  assert_eq(state.events.length(), 1)
  assert_eq(worker_status_for_execution(AwaitingAcceptance), Idle)
  let root = @fs.tmpdir(prefix="town-human-review-snapshot-")
  let path = root + "/town.json"
  @storage.save_snapshot_file(path, @storage.snapshot_of(state))
  let restored = @storage.load_snapshot_file(path).unwrap().town
  assert_eq(restored.executions[0].status, AwaitingAcceptance)
  assert_false(restored.executions[0].requires_review)
  reconcile_wenyu_review_execution(
    restored,
    entry,
    restored.executions[0],
    100,
    readback=async fn(_, _, _) { approved },
  )
  assert_eq(restored.events.length(), 1)
  assert_eq(restored.tasks[0].status, Blocked)
  assert_false(@core.has_active_work_executions(restored))
  assert_false(@core.has_retry_pending_executions(restored, 100000))
  @storage.save_snapshot_file(path, @storage.snapshot_of(restored))
  assert_eq(@storage.load_snapshot_file(path).unwrap().town, restored)
}

///|
async test "native rejected review is not automatically retried reread or reapproved" {
  let (state, entry, execution) = wenyu_review_supervision_fixture()
  let rejected = copy_execution_with(
    execution,
    status=Failed,
    summary="Book review rejected; explicit operator decision required",
    result_decision="native-book-review-rejected",
    requires_review=false,
  )
  reconcile_wenyu_review_execution(state, entry, execution, 3, readback=async fn(
    _,
    _,
    _,
  ) {
    rejected
  })
  assert_eq(state.executions[0].status, Failed)
  assert_eq(state.executions[0].next_retry_tick, None)
  assert_eq(state.events.length(), 1)
  reconcile_wenyu_review_execution(state, entry, rejected, 100, readback=async fn(
    _,
    _,
    _,
  ) {
    fail("rejected work must remain settled")
  })
  reconcile_live_executions(
    state,
    [entry],
    "/synthetic/no-snapshot",
    [],
    tick=100,
  )
  assert_eq(state.executions[0], rejected)
  assert_eq(state.events.length(), 1)
}

///|
async test "native missing legacy or unavailable review binding stays visibly unresolved" {
  let (state, entry, execution) = wenyu_review_supervision_fixture()
  reconcile_wenyu_review_execution(state, entry, execution, 3, readback=async fn(
    _,
    _,
    _,
  ) {
    fail("legacy binding missing")
  })
  assert_eq(state.executions[0].status, ReviewQueued)
  assert_true(state.executions[0].requires_review)
  assert_true(state.executions[0].summary.contains("legacy binding missing"))
  assert_eq(state.events.length(), 0)
  let approved = copy_execution_with(
    execution,
    status=AwaitingAcceptance,
    requires_review=false,
    result_decision="native-book-review-approved",
  )
  reconcile_wenyu_review_execution(state, entry, approved, 4, readback=async fn(
    _,
    _,
    _,
  ) {
    fail("Book receipt conflict")
  })
  assert_eq(state.executions[0].status, ReviewQueued)
  assert_true(state.executions[0].requires_review)
  assert_eq(state.events.length(), 0)
}
