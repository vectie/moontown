///|
async test "civic pattern manifest installs staggered schedules without running workers" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-pattern-manifest",
  )
  let snapshot_path = "\{root}/town.json"
  let summary = install_civic_pattern_scenario_manifest(
    "assets/templates/civic-patterns/wenyu-civic-patterns.json",
    snapshot_path~,
  )
  assert_true(summary.contains("Installed 11 civic communication pattern"))
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
  assert_eq(schedules.length(), 11)
  for index in 1..<schedules.length() {
    assert_true(schedules[index].next_due_ms > schedules[index - 1].next_due_ms)
  }
  for schedule in schedules {
    assert_true(
      @fs.exists(civic_salon_scenario_path(schedule.id, snapshot_path~)),
    )
  }
  assert_true(
    !@fs.exists("\{root}/books/wenyu-social-square/book/moonbook-ui-state.json"),
  )
}
