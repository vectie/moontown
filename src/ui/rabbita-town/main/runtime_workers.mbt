///|
fn workers_for_model(model : Model) -> Array[WorkerSim] {
  match model.state_source {
    StateSourceKind::DemoSimulation => worker_sims(model)
    StateSourceKind::SnapshotFile => snapshot_worker_sims(model)
  }
}
