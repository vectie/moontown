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
      update_count: 0,
      review_count: 0,
      no_change_count: 0,
      failed_count: 0,
    }),
    "Clear",
  )
  assert_eq(
    professional_attention_label({
      update_count: 0,
      review_count: 2,
      no_change_count: 0,
      failed_count: 0,
    }),
    "Review",
  )
  assert_eq(
    professional_attention_label({
      update_count: 0,
      review_count: 2,
      no_change_count: 0,
      failed_count: 1,
    }),
    "Failed",
  )
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
