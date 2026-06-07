///|
async test "generic book-quality repair review stays in autonomous retry loop" {
  let state = goal_supervision_test_state()
  let goal = standing_watch_goal_fixture(
    id="book-quality-repair-wenyu-resident-twins",
    title="Repair resident twins",
    prompt="repair",
    book_id="wenyu-resident-twins",
  )
  state.register_execution(
    review_queued_standing_watch_execution(
      "standing-book-quality-repair-wenyu-resident-twins-tick-20", "wenyu-resident-twins",
      "packet-new", "new.json", "run-new", "Detached MoonClaw import completed for packet-new; inline run finished.\nkeeper_auto_triage: reconciled_from_watcher_ledger\nreconciled_watcher_decision: NeedsReview",
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [
      goal_supervision_book_entry(
        id="wenyu-resident-twins",
        name="Wenyu Resident Twins",
        purpose="Resident memory",
        workspace_root="/tmp/moontown-review-autonomous-repair/book",
      ),
    ],
    "/tmp/moontown-review-autonomous-repair/town.json",
    [goal],
  )
  let current = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-resident-twins-tick-20",
  ).unwrap()
  assert_eq(current.status, @core.TaskExecutionStatus::Completed)
  assert_eq(current.result_decision, "repair-still-open")
  assert_false(current.requires_review)
  assert_true(current.summary.contains("keeper_auto_triage: repair_still_open"))
}
