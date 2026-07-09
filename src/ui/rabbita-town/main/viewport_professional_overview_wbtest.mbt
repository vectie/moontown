///|
test "professional overview town health labels separate healthy paused and recovery states" {
  let model = init_model()
  assert_eq(professional_town_health_label(model), "Healthy")
  assert_eq(professional_town_health_label({ ..model, paused: true }), "Paused")
  assert_eq(
    professional_town_health_label({ ..model, pressure: 90 }),
    "Needs attention",
  )
}

///|
test "professional overview attention summary prioritizes failed and review work" {
  assert_eq(
    professional_attention_label({
      review_count: 0,
      failed_count: 0,
    }),
    "Clear",
  )
  assert_eq(
    professional_attention_label({
      review_count: 2,
      failed_count: 0,
    }),
    "Review",
  )
  assert_eq(
    professional_attention_label({
      review_count: 2,
      failed_count: 1,
    }),
    "Failed",
  )
}

///|
test "professional overview attention summary includes execution review state" {
  let model = { ..init_model(), watcher_records: [] }
  let summary = professional_attention_summary(
    model,
    [
      @core.TaskExecutionRecord::new(
        task_id="task-review",
        book_id="wenyu-town-shell",
        packet_id="packet-review",
        packet_path="packets/packet-review.json",
        status=ReviewQueued,
        summary="Review queued.",
        output_contract="keeper.plan.packet.v1",
      ),
    ],
  )
  assert_eq(summary.review_count, 1)
  assert_eq(professional_attention_label(summary), "Review")
  assert_eq(professional_attention_chip_text(summary), "Review: 1")
  assert_true(professional_attention_detail(summary).contains("town work"))
}

///|
test "professional overview watch detail hides implementation ids" {
  assert_eq(
    professional_watch_detail({
      enabled_count: 0,
      disabled_count: 0,
      active_goal: None,
    }),
    "Save a standing watch to start durable topic monitoring.",
  )
  assert_eq(
    professional_watch_detail({
      enabled_count: 1,
      disabled_count: 1,
      active_goal: None,
    }),
    "1 saved watch is currently paused.",
  )
}
