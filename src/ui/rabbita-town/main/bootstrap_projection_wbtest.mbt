///|
fn projection_test_ready_snapshot(model : Model) -> ProjectionSnapshot {
  { town: simulation_state(model), event_count: 0 }
}

///|
test "browser bootstrap uses live state unless demo is explicit" {
  assert_true(
    state_source_for_browser(true, false) == StateSourceKind::SnapshotFile,
  )
  assert_true(
    state_source_for_browser(true, true) == StateSourceKind::DemoSimulation,
  )
  assert_true(
    state_source_for_browser(false, false) == StateSourceKind::DemoSimulation,
  )
}

///|
test "model projection snapshot predicates distinguish demo and waiting states" {
  let model = init_model()
  let demo_model = { ..model, state_source: StateSourceKind::DemoSimulation }
  assert_eq(model_projection_snapshot_ready(demo_model), false)
  assert_eq(model_projection_snapshot_waiting(demo_model), false)
  let waiting_model = {
    ..model,
    state_source: StateSourceKind::SnapshotFile,
    projection_snapshot: None,
  }
  assert_eq(model_projection_snapshot_ready(waiting_model), false)
  assert_eq(model_projection_snapshot_waiting(waiting_model), true)
}

///|
test "model projection snapshot predicates detect a ready snapshot source" {
  let model = init_model()
  let ready_model = {
    ..model,
    state_source: StateSourceKind::SnapshotFile,
    projection_snapshot: Some(projection_test_ready_snapshot(model)),
  }
  assert_eq(model_projection_snapshot_ready(ready_model), true)
  assert_eq(model_projection_snapshot_waiting(ready_model), false)
  assert_eq(model_operational_data_ready(ready_model), true)
}

///|
test "empty snapshots do not unlock operational area details" {
  let model = init_model()
  let sparse_snapshot = { town: snapshot_placeholder_state(), event_count: 0 }
  let sparse_model = {
    ..model,
    state_source: StateSourceKind::SnapshotFile,
    projection_snapshot: Some(sparse_snapshot),
  }
  assert_eq(model_projection_snapshot_ready(sparse_model), false)
  assert_eq(model_operational_data_ready(sparse_model), false)
}

///|
test "snapshot mode never falls back to demo work" {
  let model = {
    ..init_model(),
    state_source: StateSourceKind::SnapshotFile,
    projection_snapshot: None,
  }
  assert_true(tasks_for_model(model).is_empty())
  assert_true(executions_for_model(model).is_empty())
  assert_true(workers_for_model(model).is_empty())
  assert_true(
    runtime_availability({ ..model, snapshot_version: 1 }) is OfflineRuntime,
  )
}
