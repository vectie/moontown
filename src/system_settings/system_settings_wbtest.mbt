///|
test "defaults validate and expose every value through the catalog" {
  let settings = default_system_settings()
  validate_system_settings(settings)
  let catalog = system_settings_catalog(settings)
  assert_eq(catalog.length(), 30)
  assert_true(
    catalog
    .map(item => item.stringify())
    .join("\n")
    .contains("max_live_external_executions"),
  )
}

///|
test "validation rejects inconsistent execution capacity" {
  let invalid = {
    ..default_system_settings(),
    max_concurrent_tasks: 4,
    max_live_external_executions: 5,
  }
  try validate_system_settings(invalid) catch {
    error => assert_true("\{error}".contains("cannot exceed"))
  } noraise {
    _ => fail("inconsistent capacity must fail")
  }
}
