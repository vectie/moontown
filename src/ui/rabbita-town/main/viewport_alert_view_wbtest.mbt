///|
test "alert strip chip class separates calm recovery and alert states" {
  assert_eq(alert_strip_chip_class([no_active_alert_text]), "chip-calm")
  assert_eq(
    alert_strip_chip_class([mayor_recovery_alert_text]),
    "chip-recovery",
  )
  assert_eq(alert_strip_chip_class(["Queue pressure is high"]), "chip-alert")
  assert_eq(
    alert_strip_chip_class(["Queue pressure is high", "Budget is thin"]),
    "chip-alert",
  )
}

///|
test "all alerts emits calm fallback when no conditions are active" {
  let model = {
    ..init_model(),
    pressure: 30,
    stability: 70,
    budget: 70,
    energy: 70,
  }
  let scene = town_scene(model)
  let alerts = all_alerts(scene, model)
  assert_eq(alerts.length(), 1)
  assert_eq(alerts[0], no_active_alert_text)
}

///|
test "all alerts prioritizes mayor recovery over lower-priority alerts" {
  let model = {
    ..init_model(),
    pressure: 90,
    stability: 20,
    budget: 10,
    energy: 10,
  }
  let scene = town_scene(model)
  let alerts = all_alerts(scene, model)
  assert_eq(alerts.length(), 1)
  assert_eq(alerts[0], mayor_recovery_alert_text)
}
