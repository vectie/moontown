///|
test "ai garden scenario bonus keeps health policy named" {
  assert_eq(ai_garden_scenario_bonus(4), 20)
}

///|
test "ai garden scenario count responds to town tick and recovery" {
  let model = init_model()
  assert_eq(ai_garden_scenario_count({ ..model, tick: 1 }), 3)
  assert_eq(ai_garden_scenario_count({ ..model, tick: 4 }), 4)
  assert_eq(ai_garden_scenario_count({ ..model, pressure: 90, tick: 4 }), 2)
}
