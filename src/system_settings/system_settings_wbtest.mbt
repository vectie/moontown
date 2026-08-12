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
  guard settings.to_json() is Object(value_fields) else {
    fail("system settings must serialize as an object")
  }
  let catalog_keys : Array[String] = []
  for item in catalog {
    guard item is Object(fields) && fields.get("key") is Some(String(key)) else {
      fail("every catalog entry must expose a string key")
    }
    assert_false(catalog_keys.contains(key))
    catalog_keys.push(key)
  }
  assert_eq(catalog_keys.length(), value_fields.length())
  for key, _ in value_fields {
    assert_true(catalog_keys.contains(key))
  }
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
