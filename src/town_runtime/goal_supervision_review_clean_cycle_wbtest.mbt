///|
async test "review queued standing watch closes when newer cycle is clean" {
  let state = goal_supervision_test_state()
  let goal = standing_watch_goal_fixture(
    id="book-quality-repair-wenyu-physical-bridge",
    title="Repair physical bridge",
    prompt="repair",
    book_id="wenyu-physical-bridge",
  )
  state.register_execution(
    review_queued_standing_watch_execution(
      "standing-book-quality-repair-wenyu-physical-bridge-tick-10", "wenyu-physical-bridge",
      "packet-old", "old.json", "run-old", "older review",
    ),
  )
  state.register_execution(
    completed_no_change_standing_watch_execution(
      task_id="standing-book-quality-repair-wenyu-physical-bridge-tick-20",
      book_id="wenyu-physical-bridge",
      packet_id="packet-new",
      packet_path="new.json",
      run_id="run-new",
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [],
    "/tmp/moontown-review-clean-superseded/town.json",
    [goal],
  )
  let old = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-physical-bridge-tick-10",
  ).unwrap()
  let current = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-physical-bridge-tick-20",
  ).unwrap()
  assert_eq(old.status, Completed)
  assert_eq(old.result_decision, "superseded-review")
  assert_true(!old.requires_review)
  assert_eq(current.status, Completed)
  assert_eq(current.result_decision, "NoChange")
  assert_true(!current.requires_review)
}
