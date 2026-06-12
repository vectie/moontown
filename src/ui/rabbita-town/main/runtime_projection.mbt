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
fn next_state_source(source : StateSourceKind) -> StateSourceKind {
  match source {
    StateSourceKind::DemoSimulation => StateSourceKind::SnapshotFile
    StateSourceKind::SnapshotFile => StateSourceKind::DemoSimulation
  }
}

///|
fn state_source_label(source : StateSourceKind) -> String {
  match source {
    StateSourceKind::DemoSimulation => "Demo Simulation"
    StateSourceKind::SnapshotFile => "Projection Snapshot"
  }
}

///|
fn state_source_detail(model : Model) -> String {
  match model.state_source {
    StateSourceKind::DemoSimulation =>
      "Live civic simulation: mayor supervision keeps services, agents, quests, and town health cycling 24/7 while Resident Twins stay limited to projection-safe summaries."
    StateSourceKind::SnapshotFile =>
      match model.projection_snapshot {
        Some(snapshot) if projection_snapshot_ready(snapshot) =>
          "Projection snapshot mode is loaded from `.moontown/town.json` with \{snapshot.town.books.length()} books, \{snapshot.town.workers.length()} workers, \{snapshot.town.tasks.length()} queued tasks, and \{snapshot.event_count} events."
        Some(_) =>
          "Projection snapshot file was found but does not yet contain a usable town runtime projection, so the shell stays on demo supervision until the bridge publishes real books, workers, or tasks."
        None =>
          "Projection snapshot mode shows the MoonBook-to-browser bridge placeholder until the bundle can load `.moontown/town.json` or a generated runtime projection."
      }
  }
}

///|
fn state_source_options() -> Array[StateSourceKind] {
  [DemoSimulation, SnapshotFile]
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
