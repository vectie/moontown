///|
fn mayor_recovery_active(model : Model) -> Bool {
  model.pressure > 76 ||
  model.stability < 36 ||
  model.energy < 28 ||
  model.budget < 24
}

///|
fn clamp_metric(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn town_scene(model : Model) -> @ui.SceneRenderModel {
  let state = state_for_model(model)
  let report = @health.inspect_town(state)
  @ui.build_scene_render(@ui.build_dashboard(state, report))
}

///|
fn state_for_model(model : Model) -> @core.TownState {
  match model.state_source {
    StateSourceKind::DemoSimulation => simulation_state(model)
    StateSourceKind::SnapshotFile => projection_state(model)
  }
}

///|
fn projection_state(model : Model) -> @core.TownState {
  match model.projection_snapshot {
    Some(snapshot) =>
      if projection_snapshot_ready(snapshot) {
        snapshot.town
      } else {
        snapshot_placeholder_state(model)
      }
    None => snapshot_placeholder_state(model)
  }
}

///|
fn tasks_for_model(model : Model) -> Array[@core.TownTask] {
  match model.state_source {
    StateSourceKind::SnapshotFile =>
      match model.projection_snapshot {
        Some(snapshot) =>
          if projection_snapshot_ready(snapshot) &&
            !snapshot.town.tasks.is_empty() {
            snapshot.town.tasks
          } else {
            task_specs(model)
          }
        _ => task_specs(model)
      }
    StateSourceKind::DemoSimulation => task_specs(model)
  }
}

///|
fn executions_for_model(model : Model) -> Array[@core.TaskExecutionRecord] {
  match model.state_source {
    StateSourceKind::SnapshotFile =>
      match model.projection_snapshot {
        Some(snapshot) =>
          if projection_snapshot_ready(snapshot) &&
            !snapshot.town.executions.is_empty() {
            snapshot.town.executions
          } else {
            execution_specs(model)
          }
        _ => execution_specs(model)
      }
    StateSourceKind::DemoSimulation => execution_specs(model)
  }
}

///|
