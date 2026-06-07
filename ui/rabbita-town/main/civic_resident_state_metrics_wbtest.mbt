///|
test "resident state metrics count private scopes and review records" {
  let model = init_model()
  assert_eq(resident_private_scope_count(model), 1)
  assert_eq(resident_review_queue_count(model), 2)
}

///|
test "resident twin resident plan rotates with the active resident" {
  let model = init_model()
  assert_true(
    resident_twins_resident_plan({ ..model, tick: 0 }).contains("policy quest"),
  )
  assert_true(
    resident_twins_resident_plan({ ..model, tick: 1 }).contains("Talent Avenue"),
  )
  assert_eq(
    resident_twins_resident_plan({ ..model, tick: resident_sims(model).length() }),
    resident_twins_resident_plan({ ..model, tick: 0 }),
  )
}
