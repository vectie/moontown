///|
test "runtime status chip labels live demo simulation" {
  let chip = runtime_status_chip_for_state(
    StateSourceKind::DemoSimulation,
    paused=false,
  )
  assert_eq(chip.text, "Preview live")
  assert_eq(chip.class_name, "chip-live")
}

///|
test "runtime status chip labels paused demo simulation" {
  let chip = runtime_status_chip_for_state(
    StateSourceKind::DemoSimulation,
    paused=true,
  )
  assert_eq(chip.text, "Preview paused")
  assert_eq(chip.class_name, "chip-alert")
}

///|
test "runtime status chip labels snapshot source neutrally even when paused" {
  let chip = runtime_status_chip_for_state(
    StateSourceKind::SnapshotFile,
    paused=true,
  )
  assert_eq(chip.text, "Town data connected")
  assert_eq(chip.class_name, "chip-neutral")
}
