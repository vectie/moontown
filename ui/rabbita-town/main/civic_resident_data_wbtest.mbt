///|
test "resident data keeps the expected demo roster shape" {
  let residents = resident_sims(init_model())
  assert_eq(residents.length(), 3)
  assert_eq(residents[0].name, "Li / Edge AI OPC")
  assert_eq(residents[1].zone, "Social Square")
  assert_eq(residents[2].privacy_scope, "Public-safe")
}

///|
test "resident data marks the first resident focused under pressure" {
  let model = init_model()
  assert_eq(resident_sims({ ..model, pressure: 34 })[0].mood, "Curious")
  assert_eq(resident_sims({ ..model, pressure: 80 })[0].mood, "Focused")
}
