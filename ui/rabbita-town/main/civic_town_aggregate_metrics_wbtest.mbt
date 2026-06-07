///|
test "civic town aggregate metrics expose stable tick-driven counts" {
  let model = { ..init_model(), tick: 20 }
  assert_eq(resident_count(model), 53)
  assert_eq(valley_points_redeemed(model), 21)
  assert_eq(robot_service_count(model), 14)
  assert_eq(events_today(model), social_matches().length() + 3)
  assert_eq(
    valley_points_issued(model),
    valley_points_redeemed(model) +
    resident_joins_today(model) +
    events_today(model),
  )
}

///|
test "strategy label keeps control labels centralized" {
  assert_eq(strategy_label(Strategy::Balanced), "Balanced")
  assert_eq(strategy_label(Strategy::Throughput), "Throughput")
  assert_eq(strategy_label(Strategy::Recovery), "Recovery")
}
