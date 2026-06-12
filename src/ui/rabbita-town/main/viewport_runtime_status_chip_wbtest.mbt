///|
test "runtime status chip labels live demo simulation" {
  let chip = runtime_status_chip_for_state(
    StateSourceKind::DemoSimulation,
    paused=false,
  )
  assert_eq(chip.text, "Simulation live")
  assert_eq(chip.class_name, "chip-live")
}

///|
test "runtime status chip labels paused demo simulation" {
  let chip = runtime_status_chip_for_state(
    StateSourceKind::DemoSimulation,
    paused=true,
  )
  assert_eq(chip.text, "Simulation paused")
  assert_eq(chip.class_name, "chip-alert")
}

///|
test "runtime status chip labels snapshot source neutrally even when paused" {
  let chip = runtime_status_chip_for_state(
    StateSourceKind::SnapshotFile,
    paused=true,
  )
  assert_eq(chip.text, "Snapshot bridge")
  assert_eq(chip.class_name, "chip-neutral")
}
