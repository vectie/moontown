///|
async test "generic standing watch review closes as no change" {
  let state = goal_supervision_test_state()
  let goal = standing_watch_goal_fixture(
    id="watch-embodied-robotics",
    title="Watch embodied robotics",
    prompt="watch",
    book_id="research-embodied-robotics",
  )
  state.register_execution(
    review_queued_standing_watch_execution(
      "standing-watch-embodied-robotics-tick-18142", "research-embodied-robotics",
      "packet-watch", "watch.json", "run-watch", "Detached MoonClaw import completed for packet-watch; inline run finished.\nkeeper_auto_triage: reconciled_from_watcher_ledger\nreconciled_watcher_decision: NeedsReview",
    ),
  )
  reconcile_review_queued_standing_watch_outputs(
    state,
    [
      goal_supervision_book_entry(
        id="research-embodied-robotics",
        name="Research Embodied Robotics",
        purpose="Watch embodied robotics",
        workspace_root="/tmp/moontown-review-empty-watch/book",
      ),
    ],
    "/tmp/moontown-review-empty-watch/town.json",
    [goal],
  )
  let current = @core.find_execution(
    state, "standing-watch-embodied-robotics-tick-18142",
  ).unwrap()
  assert_eq(current.status, @core.TaskExecutionStatus::Completed)
  assert_eq(current.result_decision, "NoChange")
  assert_false(current.requires_review)
  assert_true(
    current.summary.contains("keeper_auto_triage: empty_completion_no_change"),
  )
  assert_true(current.summary.contains("standing_goal_decision: no_change"))
}
