///|
test "refresh version predicate centralizes change detection" {
  assert_true(!refresh_version_changed(3, 3))
  assert_true(refresh_version_changed(4, 3))
  assert_true(refresh_version_changed(2, 3))
}

///|
test "optional refresh keeps current value when version is unchanged" {
  let refreshed = refresh_optional_snapshot(
    7,
    7,
    Some(10),
    fn() { Some(20) },
  )
  assert_true(refreshed is Some(10))
}

///|
test "optional refresh keeps current value when parser fails" {
  let refreshed = refresh_optional_snapshot(
    8,
    7,
    Some(10),
    fn() { None },
  )
  assert_true(refreshed is Some(10))
}

///|
test "optional refresh accepts parsed value when version changes" {
  let refreshed = refresh_optional_snapshot(
    8,
    7,
    Some(10),
    fn() { Some(20) },
  )
  assert_true(refreshed is Some(20))
}

///|
test "array refresh keeps current array when version is unchanged" {
  let refreshed = refresh_array_snapshot(
    7,
    7,
    [1, 2],
    fn() { [3, 4] },
  )
  assert_eq(refreshed.length(), 2)
  assert_eq(refreshed[0], 1)
  assert_eq(refreshed[1], 2)
}

///|
test "array refresh accepts parsed array when version changes" {
  let refreshed = refresh_array_snapshot(
    8,
    7,
    [1, 2],
    fn() { [3, 4] },
  )
  assert_eq(refreshed.length(), 2)
  assert_eq(refreshed[0], 3)
  assert_eq(refreshed[1], 4)
}

///|
test "refreshed state source keeps explicit snapshot mode" {
  let model = { ..init_model(), state_source: StateSourceKind::SnapshotFile }
  assert_true(
    refreshed_state_source(model, model.projection_snapshot) ==
    StateSourceKind::SnapshotFile,
  )
}

///|
test "refreshed state source keeps demo mode when no ready snapshot exists" {
  let model = {
    ..init_model(),
    state_source: StateSourceKind::DemoSimulation,
    projection_snapshot: None,
  }
  assert_true(
    refreshed_state_source(model, None) == StateSourceKind::DemoSimulation,
  )
}
