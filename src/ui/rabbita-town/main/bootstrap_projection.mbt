///|
fn parse_bootstrap_town_snapshot() -> ProjectionSnapshot? {
  let text = load_bootstrap_town_snapshot_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_visual_projection() -> VisualProjectionSnapshot? {
  let text = load_bootstrap_visual_projection_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_module_projections() -> Array[BookProjectionFragment] {
  let text = load_bootstrap_module_projections_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let index : ModuleProjectionIndex = @json.from_json(parsed) catch {
    _ => return []
  }
  ignore(index.generated_at)
  index.projections
}

///|
fn parse_bootstrap_civic_status() -> CivicServicePortfolioSnapshot? {
  let text = load_bootstrap_civic_status_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_wenyu_modules() -> Array[WenyuTownModule] {
  let text = load_bootstrap_wenyu_modules_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let config : WenyuTownModuleConfig = @json.from_json(parsed) catch {
    _ => return []
  }
  ignore(config.version)
  ignore(config.description)
  config.modules.filter(civic => civic.enabled)
}

///|
fn initial_state_source(snapshot : ProjectionSnapshot?) -> StateSourceKind {
  match snapshot {
    Some(snapshot) =>
      if projection_snapshot_ready(snapshot) {
        StateSourceKind::SnapshotFile
      } else {
        StateSourceKind::DemoSimulation
      }
    None => StateSourceKind::DemoSimulation
  }
}

///|
fn projection_snapshot_ready(snapshot : ProjectionSnapshot) -> Bool {
  !snapshot.town.books.is_empty() ||
  !snapshot.town.workers.is_empty() ||
  !snapshot.town.tasks.is_empty() ||
  !snapshot.town.executions.is_empty() ||
  !snapshot.town.events.is_empty()
}

///|
fn projection_snapshot_is_ready(snapshot : ProjectionSnapshot?) -> Bool {
  match snapshot {
    Some(snapshot) => projection_snapshot_ready(snapshot)
    None => false
  }
}

///|
fn model_projection_snapshot_ready(model : Model) -> Bool {
  model.state_source == StateSourceKind::SnapshotFile &&
  projection_snapshot_is_ready(model.projection_snapshot)
}

///|
fn model_projection_snapshot_waiting(model : Model) -> Bool {
  model.state_source == StateSourceKind::SnapshotFile &&
  !projection_snapshot_is_ready(model.projection_snapshot)
}
