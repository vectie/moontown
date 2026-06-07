///|
test "resident twins active twin rotates by tick" {
  let model = init_model()
  assert_eq(
    resident_twins_active_twin_label({ ..model, tick: 0 }),
    "Li / Edge AI OPC / Policy Hall",
  )
  assert_eq(
    resident_twins_active_twin_label({ ..model, tick: 1 }),
    "Chen / Design Automation OPC / Social Square",
  )
  assert_eq(
    resident_twins_active_twin_label({ ..model, tick: resident_sims(model).length() }),
    "Li / Edge AI OPC / Policy Hall",
  )
}

///|
test "resident twins privacy label separates private and shared projections" {
  let model = init_model()
  assert_eq(resident_private_scope_count(model), 1)
  assert_eq(resident_twins_privacy_label(model), "1 private / 2 shared")
}
