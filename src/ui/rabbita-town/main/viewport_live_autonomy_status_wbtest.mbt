///|
test "compact single-line normalizes whitespace and truncates" {
  assert_eq(
    compact_single_line(" first\nsecond\tthird ", limit=40),
    "first second third",
  )
  assert_eq(
    compact_single_line("abcdefghijklmnopqrstuvwxyz", limit=6),
    "abcdef...",
  )
}

///|
fn test_live_autonomy_snapshot(
  status? : String = "working",
  active_workers? : Int = 4,
  pending_templates? : Int = 0,
  failed_templates? : Int = 0,
  open_plan_gaps? : Int = 0,
  repair_active? : Int = 0,
  standing_goals? : Int = 0,
  enabled_goals? : Int = 0,
  disabled_goals? : Int = 0,
  next_actions? : Array[String] = [],
) -> LiveAutonomySnapshot {
  {
    generated_at_ms: "test-time",
    tick: 42,
    status,
    summary: "live test summary",
    active_worker_count: active_workers,
    review_count: 1,
    blocked_count: 0,
    accepted_update_count: 2,
    no_change_count: 3,
    failed_count: 0,
    due_goal_count: 1,
    standing_goal_count: standing_goals,
    enabled_standing_goal_count: enabled_goals,
    disabled_standing_goal_count: disabled_goals,
    planbook_open_count: open_plan_gaps,
    planbook_repair_active_count: repair_active,
    book_template_request_count: pending_templates + failed_templates,
    pending_book_template_request_count: pending_templates,
    failed_book_template_request_count: failed_templates,
    book_template_request_summary: "template request summary",
    book_template_latest_event_summary: "latest template event",
    latest_watcher_summary: "latest watcher summary",
    visual_projection_path: ".moonsuite/products/moontown/visual-projection.json",
    journal_path: ".moonsuite/products/moontown/town-journal.jsonl",
    digest_path: ".moonsuite/products/moontown/live-autonomy.md",
    planbook_change_log_path: "books/planbook/wiki/history/change-log.md",
    planbook_engineering_digest_path: "books/planbook/wiki/history/daily-engineering-digest.md",
    latest_change_summary: "latest change\nsummary",
    next_actions,
  }
}

///|
fn test_standing_goal(id : String, enabled : Bool) -> StandingGoalSnapshot {
  {
    id,
    title: "Goal \{id}",
    prompt: "watch \{id}",
    target_book_id: None,
    cadence_ticks: 30,
    next_due_tick: 0,
    last_run_tick: None,
    enabled,
    source_policy: "test",
    quality_threshold: 80,
  }
}

///|
test "live autonomy operator view exposes disconnected fallback" {
  let model = { ..init_model(), live_autonomy: None, standing_goals: [] }
  let view = live_autonomy_operator_view(model, fallback_active_workers=7)
  assert_eq(view.status_label, "not-connected")
  assert_eq(view.tone, "alert")
  assert_eq(view.active_worker_label, "7")
  assert_eq(view.template_request_count, 0)
  assert_eq(view.enabled_standing_goal_count, 0)
}

///|
test "live autonomy operator view resolves connected counts and tone" {
  let spine = test_live_autonomy_snapshot(
    pending_templates=2,
    enabled_goals=3,
    disabled_goals=1,
  )
  let model = { ..init_model(), live_autonomy: Some(spine), standing_goals: [] }
  let view = live_autonomy_operator_view(model, fallback_active_workers=0)
  assert_eq(view.status_label, "working")
  assert_eq(view.tone, "book")
  assert_eq(view.active_worker_label, "4")
  assert_eq(view.template_request_count, 2)
  assert_eq(view.pending_template_request_count, 2)
  assert_eq(view.failed_template_request_count, 0)
  assert_eq(view.enabled_standing_goal_count, 3)
  assert_eq(view.disabled_standing_goal_count, 1)
}

///|
test "live autonomy feed items centralize connected spine projection" {
  let spine = test_live_autonomy_snapshot(next_actions=[
    "first", "second", "third",
  ])
  let feed = live_autonomy_spine_feed_items(spine)
  assert_eq(feed.length(), 4)
  assert_eq(feed[0].title, "Live spine is working")
  assert_eq(feed[0].tone, "live")
  assert_eq(feed[1].title, "Live digest updated")
  assert_true(feed[1].detail.contains(spine.digest_path))
  assert_eq(feed[2].detail, "first")
  assert_eq(feed[3].detail, "second")
}

///|
test "live autonomy feed items expose template inbox state only when needed" {
  assert_true(
    live_autonomy_template_request_feed_item(test_live_autonomy_snapshot())
    is None,
  )
  let pending = live_autonomy_template_request_feed_item(
    test_live_autonomy_snapshot(pending_templates=2),
  )
  assert_eq(pending.unwrap().tone, "book")
  assert_true(pending.unwrap().detail.contains("2 pending, 0 failed"))
  let failed = live_autonomy_template_request_feed_item(
    test_live_autonomy_snapshot(pending_templates=1, failed_templates=1),
  )
  assert_eq(failed.unwrap().tone, "alert")
  assert_true(failed.unwrap().detail.contains("Latest event"))
}

///|
test "live autonomy feed items use recovery tone for next actions" {
  let spine = test_live_autonomy_snapshot(status="needs-recovery", next_actions=[
    "recover",
  ])
  assert_eq(live_autonomy_next_action_tone(spine), "alert")
  let feed = live_autonomy_spine_feed_items(spine)
  assert_eq(feed[2].title, "Mayor next action")
  assert_eq(feed[2].tone, "alert")
}

///|
test "live autonomy next action feed projection caps visible actions" {
  let spine = test_live_autonomy_snapshot(next_actions=[
    "first", "second", "third",
  ])
  assert_eq(live_autonomy_next_action_feed_limit, 2)
  assert_true(!live_autonomy_next_action_limit_reached(1))
  assert_true(live_autonomy_next_action_limit_reached(2))
  let items = live_autonomy_next_action_feed_items(spine)
  assert_eq(items.length(), 2)
  assert_eq(items[0].detail, "first")
  assert_eq(items[1].detail, "second")
}

///|
test "live autonomy next action feed item owns title and tone" {
  let spine = test_live_autonomy_snapshot(status="needs-recovery")
  let item = live_autonomy_next_action_feed_item(spine, "recover now")
  assert_eq(item.title, "Mayor next action")
  assert_eq(item.detail, "recover now")
  assert_eq(item.tone, "alert")
}

///|
test "live autonomy disconnected feed item is explicit" {
  let item = live_autonomy_disconnected_feed_item()
  assert_eq(item.tone, "alert")
  assert_true(item.title.contains("not connected"))
  assert_true(item.detail.contains("live refresh"))
}

///|
test "live autonomy operator view falls back to loaded standing goals" {
  let spine = test_live_autonomy_snapshot(
    standing_goals=2,
    enabled_goals=0,
    disabled_goals=0,
  )
  let model = {
    ..init_model(),
    live_autonomy: Some(spine),
    standing_goals: [
      test_standing_goal("enabled", true),
      test_standing_goal("disabled", false),
    ],
  }
  let view = live_autonomy_operator_view(model, fallback_active_workers=0)
  assert_eq(view.enabled_standing_goal_count, 1)
  assert_eq(view.disabled_standing_goal_count, 1)
}
