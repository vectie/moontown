///|
fn ai_garden_scenario_bonus(scenario_count : Int) -> Int {
  scenario_count * 5
}

///|
fn ai_garden_scenario_count(model : Model) -> Int {
  let base = 3
  if mayor_recovery_active(model) {
    base - 1
  } else if model.tick % 4 == 0 {
    base + 1
  } else {
    base
  }
}
