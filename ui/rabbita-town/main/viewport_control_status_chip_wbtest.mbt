///|
test "control status chip labels live demo state" {
  let chip = control_status_chip_from_inputs(
    projection_ready=false,
    projection_waiting=false,
    paused=false,
  )
  assert_eq(chip.text, "Live")
  assert_eq(chip.class_name, "chip-live")
}

///|
test "control status chip labels paused demo state" {
  let chip = control_status_chip_from_inputs(
    projection_ready=false,
    projection_waiting=false,
    paused=true,
  )
  assert_eq(chip.text, "Paused")
  assert_eq(chip.class_name, "chip-alert")
}

///|
test "control status chip labels ready projection bridge" {
  let chip = control_status_chip_from_inputs(
    projection_ready=true,
    projection_waiting=false,
    paused=false,
  )
  assert_eq(chip.text, "Bridge ready")
  assert_eq(chip.class_name, "chip-live")
}

///|
test "control status chip labels paused projection bridge" {
  let chip = control_status_chip_from_inputs(
    projection_ready=true,
    projection_waiting=false,
    paused=true,
  )
  assert_eq(chip.text, "Bridge paused")
  assert_eq(chip.class_name, "chip-alert")
}

///|
test "control status chip labels waiting projection bridge" {
  let chip = control_status_chip_from_inputs(
    projection_ready=false,
    projection_waiting=true,
    paused=false,
  )
  assert_eq(chip.text, "Bridge waiting")
  assert_eq(chip.class_name, "chip-live")
}
