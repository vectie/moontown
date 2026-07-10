///|
test "town launchpad health labels separate healthy paused and recovery states" {
  let model = init_model()
  assert_eq(professional_town_health_label(model), "Healthy")
  assert_eq(professional_town_health_label({ ..model, paused: true }), "Paused")
  assert_eq(
    professional_town_health_label({ ..model, pressure: 90 }),
    "Needs attention",
  )
}

///|
test "town launchpad attention summary prioritizes failed and review work" {
  assert_eq(
    professional_attention_label({ review_count: 0, failed_count: 0 }),
    "Clear",
  )
  assert_eq(
    professional_attention_label({ review_count: 2, failed_count: 0 }),
    "Review",
  )
  assert_eq(
    professional_attention_label({ review_count: 2, failed_count: 1 }),
    "Failed",
  )
}

///|
test "town launchpad attention summary includes execution review state" {
  let model = { ..init_model(), watcher_records: [] }
  let summary = professional_attention_summary(model, [
    @core.TaskExecutionRecord::new(
      task_id="task-review",
      book_id="wenyu-town-shell",
      packet_id="packet-review",
      packet_path="packets/packet-review.json",
      status=ReviewQueued,
      summary="Review queued.",
      output_contract="keeper.plan.packet.v1",
    ),
  ])
  assert_eq(summary.review_count, 1)
  assert_eq(professional_attention_label(summary), "Review")
  assert_eq(professional_attention_chip_text(summary), "Review 1")
  assert_eq(professional_attention_detail(summary), "1 review")
}

///|
test "town launchpad book queue counts only pending work" {
  let model = {
    ..init_model(),
    book_template_requests: [
      { status: "pending" },
      { status: "retry" },
      { status: "installed" },
    ],
  }
  assert_eq(professional_book_queue_count(model), 2)
  assert_eq(professional_book_queue_detail(model), "2 setup")
}

///|
test "town launchpad reports disconnected runtime truthfully" {
  let model = {
    ..init_model(),
    state_source: StateSourceKind::SnapshotFile,
    projection_snapshot: None,
    snapshot_version: 1,
  }
  assert_eq(professional_town_health_label(model), "Offline")
  assert_eq(professional_town_health_detail(model), "No live snapshot")
  assert_eq(
    town_launchpad_alert_label([no_active_alert_text], model),
    "Town offline",
  )
}

///|
test "town launchpad watch detail hides implementation ids" {
  assert_eq(
    professional_watch_detail({
      enabled_count: 0,
      disabled_count: 0,
      active_goal: None,
    }),
    "Ready to save",
  )
  assert_eq(
    professional_watch_detail({
      enabled_count: 1,
      disabled_count: 1,
      active_goal: None,
    }),
    "1 paused",
  )
}
