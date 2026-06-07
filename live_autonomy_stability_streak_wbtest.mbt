///|
async test "live autonomy stable waiting streak increments across journal probes" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-stable-streak-check",
  )
  let snapshot_path = workspace.snapshot_path
  write_live_autonomy_journal_probe_lines(snapshot_path, [
    live_autonomy_journal_probe_line(10),
    live_autonomy_journal_probe_line(11),
  ])
  assert_eq(
    prior_live_autonomy_stable_waiting_observation_streak(snapshot_path, 12),
    2,
  )
}

///|
async test "live autonomy stable waiting streak resets on due journal work" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-stable-reset-check",
  )
  let snapshot_path = workspace.snapshot_path
  write_live_autonomy_journal_probe_lines(snapshot_path, [
    live_autonomy_journal_probe_line(10),
    live_autonomy_journal_probe_line(11, due_goal_count=1),
    live_autonomy_journal_probe_line(12),
  ])
  assert_eq(
    prior_live_autonomy_stable_waiting_observation_streak(snapshot_path, 13),
    1,
  )
  let due_probe = LiveAutonomyStabilityProbe::{
    tick: 99,
    active_worker_count: 0,
    review_count: 0,
    blocked_count: 0,
    failed_count: 0,
    due_goal_count: 1,
    planbook_open_count: 0,
    planbook_repair_active_count: 0,
    pending_book_template_request_count: 0,
    failed_book_template_request_count: 0,
  }
  assert_false(live_autonomy_stability_probe_is_stable(due_probe))
  assert_true(
    live_autonomy_stable_waiting_blockers_for({
      active_workers: 0,
      review: 0,
      blocked: 0,
      failed: 0,
      due_goals: 1,
      planbook_open: 0,
      planbook_repair_active: 0,
      pending_book_template_requests: 0,
      failed_book_template_requests: 0,
    }).any(fn(blocker) { blocker.contains("due standing goals") }),
  )
}
