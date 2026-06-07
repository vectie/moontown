///|
async test "superseded standing watch review is not reopened from ledger" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-superseded-review-ledger-wbtest",
  )
  let snapshot_path = "\{root}/town.json"
  let goal = standing_watch_goal_fixture(
    id="book-quality-repair-wenyu-physical-bridge",
    title="Repair physical bridge",
    prompt="repair",
    book_id="wenyu-physical-bridge",
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=10,
      target_book_id="wenyu-physical-bridge",
      decision=@core.WatcherDecisionKind::NeedsReview,
      detail="Detached MoonClaw import completed; inline run finished.",
      task_id=Some("standing-book-quality-repair-wenyu-physical-bridge-tick-10"),
      run_id=Some("run-old"),
      next_due_tick=70,
    ),
  )
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-book-quality-repair-wenyu-physical-bridge-tick-10",
      book_id="wenyu-physical-bridge",
      packet_id="packet-old",
      packet_path="old.json",
      run_id=Some("run-old"),
      status=@core.TaskExecutionStatus::Completed,
      summary="older review\nkeeper_auto_triage: superseded_review",
      result_decision="superseded-review",
      requires_review=false,
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
  reconcile_persisted_standing_watch_records(state, snapshot_path, [goal])
  let old = @core.find_execution(
    state, "standing-book-quality-repair-wenyu-physical-bridge-tick-10",
  ).unwrap()
  assert_eq(old.status, @core.TaskExecutionStatus::Completed)
  assert_eq(old.result_decision, "superseded-review")
  assert_true(!old.requires_review)
  assert_true(old.summary.contains("superseded_review"))
  assert_false(old.summary.contains("reconciled_from_watcher_ledger"))
}
