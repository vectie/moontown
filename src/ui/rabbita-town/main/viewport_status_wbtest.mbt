///|
test "class suffix helper includes suffix only when enabled" {
  assert_eq(class_suffix_when(true, " selected"), " selected")
  assert_eq(class_suffix_when(false, " selected"), "")
  assert_eq(class_suffix_when(true, " is-active"), " is-active")
}

///|
test "chip class helper maps known tones and neutral fallback" {
  assert_eq(chip_class_for_tone("alert"), "chip-alert")
  assert_eq(chip_class_for_tone("book"), "chip-book")
  assert_eq(chip_class_for_tone("live"), "chip-live")
  assert_eq(chip_class_for_tone("calm"), "chip-calm")
  assert_eq(chip_class_for_tone("clock"), "chip-clock")
  assert_eq(chip_class_for_tone("recovery"), "chip-recovery")
  assert_eq(chip_class_for_tone("unknown"), "chip-neutral")
}
