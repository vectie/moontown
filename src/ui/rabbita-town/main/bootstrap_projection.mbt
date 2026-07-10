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
fn parse_bootstrap_book_template_requests() -> Array[
  BookTemplateRequestSnapshot,
] {
  let text = load_bootstrap_book_template_requests_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let ledger : BookTemplateRequestLedgerSnapshot = @json.from_json(parsed) catch {
    _ => return []
  }
  ledger.requests
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
fn initial_state_source() -> StateSourceKind {
  state_source_for_browser(
    browser_location_available(),
    current_browser_query_param("demo") == "1",
  )
}

///|
fn state_source_for_browser(
  browser_available : Bool,
  demo_requested : Bool,
) -> StateSourceKind {
  if !browser_available || demo_requested {
    StateSourceKind::DemoSimulation
  } else {
    StateSourceKind::SnapshotFile
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
fn projection_snapshot_has_operational_data(
  snapshot : ProjectionSnapshot,
) -> Bool {
  !snapshot.town.workers.is_empty() ||
  !snapshot.town.tasks.is_empty() ||
  !snapshot.town.executions.is_empty()
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

///|
fn model_operational_data_ready(model : Model) -> Bool {
  if model.state_source == StateSourceKind::DemoSimulation {
    return true
  }
  match model.projection_snapshot {
    Some(snapshot) =>
      model.state_source == StateSourceKind::SnapshotFile &&
      projection_snapshot_has_operational_data(snapshot)
    None => false
  }
}
