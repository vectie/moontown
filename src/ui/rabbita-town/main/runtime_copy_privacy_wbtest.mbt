///|
test "runtime browser copy redacts arbitrary absolute paths but keeps result routes" {
  assert_true(
    energy_valley_runtime_copy_contains_local_path(
      "artifact=/workspace/moontown/private/report.md",
    ),
  )
  assert_true(
    energy_valley_runtime_copy_contains_local_path(
      "审阅（/Volumes/research/private/report.md）",
    ),
  )
  assert_false(
    energy_valley_runtime_copy_contains_local_path(
      "结果见 /book-output/research/report.html",
    ),
  )
}
