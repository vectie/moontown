///|
test "resident initials remain available to canonical inspectors" {
  assert_eq(worker_avatar_initials("Mayor Keeper"), "MK")
  assert_eq(worker_avatar_initials("   "), "??")
}
