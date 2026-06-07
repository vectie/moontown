///|
async test "review queued standing watch keeps only latest review per goal active" {
  let state = goal_supervision_test_state()
  let goal = standing_watch_goal_fixture(
    id="book-quality-repair-wenyu-resident-twins",
    title="Repair resident twins",
    prompt="repair",
    book_id="wenyu-resident-twins",
  )
  state.register_execution(
    review_queued_standing_watch_execution(
      "standing-book-quality-repair-wenyu-resident-twins-tick-10", "wenyu-resident-twins",
      "packet-old", "old.json", "run-old", "older review",
    ),
  )
  state.register_execution(
    review_queued_standing_watch_execution(
      "standing-book-quality-repair-wenyu-resident-twins-tick-20", "wenyu-resident-twins",
      "packet-new", "new.json", "run-new", "newer review",
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [],
    "/tmp/moontown-review-superseded/town.json",
    [goal],
  )
  let old = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-resident-twins-tick-10",
  ).unwrap()
  let current = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-resident-twins-tick-20",
  ).unwrap()
  assert_eq(old.status, @core.TaskExecutionStatus::Completed)
  assert_eq(old.result_decision, "superseded-review")
  assert_true(!old.requires_review)
  assert_eq(current.status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(current.requires_review)
}
