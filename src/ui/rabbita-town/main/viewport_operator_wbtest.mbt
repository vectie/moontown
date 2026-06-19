///|
test "operator template request tone prioritizes failed then pending" {
  assert_eq(operator_template_request_tone(0, 0), "neutral")
  assert_eq(operator_template_request_tone(2, 0), "book")
  assert_eq(operator_template_request_tone(0, 1), "alert")
  assert_eq(operator_template_request_tone(2, 1), "alert")
}

///|
test "operator template request chip class delegates tone policy" {
  assert_eq(
    operator_template_request_chip_class({
      ..operator_console_metrics(init_model(), []),
      template_request_tone: "book",
    }),
    "chip-book",
  )
  assert_eq(
    operator_template_request_chip_class({
      ..operator_console_metrics(init_model(), []),
      template_request_tone: "alert",
    }),
    "chip-alert",
  )
  assert_eq(
    operator_template_request_chip_class({
      ..operator_console_metrics(init_model(), []),
      template_request_tone: "other",
    }),
    "chip-neutral",
  )
}

///|
fn operator_metrics_test_record() -> WatcherRunRecordSnapshot {
  {
    goal_id: "research-opc",
    tick: 9,
    target_book_id: "research-opc",
    decision: "NeedsReview",
    delta_score: 4,
    new_source_count: 6,
    checked_sources_count: Some(12),
    new_sources_found: Some(7),
    accepted_facts_count: Some(3),
    rejected_facts_count: Some(2),
    wiki_pages_changed_count: Some(5),
    book_changed: Some("partial"),
    detail: "Needs review\nbecause evidence changed.",
    task_id: None,
    run_id: None,
    next_due_tick: 39,
  }
}

///|
test "latest watcher metric view normalizes missing and present records" {
  let missing = latest_watcher_metric_view(None)
  assert_eq(missing.decision, "Waiting")
  assert_eq(missing.sources, "0")
  assert_eq(missing.checked, "n/a")
  assert_eq(missing.book_changed, "unknown")

  let present = latest_watcher_metric_view(Some(operator_metrics_test_record()))
  assert_eq(present.decision, "NeedsReview")
  assert_eq(present.sources, "6")
  assert_eq(present.checked, "12")
  assert_eq(present.accepted, "3")
  assert_eq(present.wiki, "5")
  assert_eq(present.book_changed, "partial")
  assert_eq(present.detail, "Needs review")
}

///|
test "operator progress view falls back without daemon or active goal" {
  let model = { ..init_model(), daemon_snapshot: None, standing_goals: [] }
  let progress = operator_progress_view(model)
  assert_eq(progress.progress_detail, "No enabled standing goal found.")
  assert_eq(progress.daemon_identity, "daemon waiting")
  assert_eq(progress.active_goal_count, 0)
}

///|
test "operator console metrics carries connected live autonomy projection" {
  let spine = test_live_autonomy_snapshot(
    active_workers=9,
    pending_templates=2,
    failed_templates=1,
    enabled_goals=4,
    disabled_goals=2,
  )
  let metrics = operator_console_metrics(
    { ..init_model(), live_autonomy: Some(spine), standing_goals: [] },
    [],
  )
  assert_eq(metrics.live_status, "working")
  assert_eq(metrics.live_summary, "live test summary")
  assert_true(metrics.live_detail.contains("tick 42 generated at test-time"))
  assert_eq(metrics.live_tone, "alert")
  assert_eq(metrics.live_active_worker_label, "9")
  assert_eq(metrics.live_enabled_standing_goal_count, 4)
  assert_eq(metrics.live_disabled_standing_goal_count, 2)
  assert_eq(metrics.template_request_count, 3)
  assert_eq(metrics.pending_template_requests, 2)
  assert_eq(metrics.failed_template_requests, 1)
  assert_eq(metrics.template_request_tone, "alert")
  assert_eq(metrics.template_request_summary, "template request summary")
  assert_eq(metrics.template_latest_event_summary, "latest template event")
}

///|
test "operator console metrics uses worker fallback when live spine is missing" {
  let metrics = operator_console_metrics(
    { ..init_model(), live_autonomy: None },
    [
      civic_metric_test_worker(energy=80, load=10),
      civic_metric_test_worker(
        energy=70,
        load=20,
        status=Waiting,
      ),
    ],
  )
  assert_eq(metrics.live_status, "not-connected")
  assert_eq(metrics.live_active_worker_label, "1")
  assert_eq(metrics.live_tone, "alert")
}
