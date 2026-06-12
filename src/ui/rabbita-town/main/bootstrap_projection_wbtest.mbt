///|
fn projection_test_ready_snapshot(model : Model) -> ProjectionSnapshot {
  { town: simulation_state(model), event_count: 0 }
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
}
