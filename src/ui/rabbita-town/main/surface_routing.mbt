///|
priv enum TownSurfaceRoute {
  CanonicalEnergyValley
  OperationsConsole
}

///|
fn town_surface_route(
  pathname : String,
  surface : String,
  handoff_requested : Bool,
) -> TownSurfaceRoute {
  if handoff_requested {
    CanonicalEnergyValley
  } else if pathname.has_suffix("/operations.html") || surface == "operations" {
    OperationsConsole
  } else {
    CanonicalEnergyValley
  }
}

///|
fn browser_handoff_requested() -> Bool {
  !current_browser_query_param("moonflow_run").is_empty() ||
  !current_browser_query_param("moonflow_handoff").is_empty() ||
  !current_browser_query_param("handoff_url").is_empty()
}

///|
fn current_town_surface_route() -> TownSurfaceRoute {
  if !browser_location_available() {
    CanonicalEnergyValley
  } else {
    town_surface_route(
      current_browser_pathname(),
      current_browser_query_param("surface"),
      browser_handoff_requested(),
    )
  }
}

///|
fn canonical_energy_valley_href() -> String {
  "./index.html?seed=\{active_energy_valley_seed()}"
}

///|
fn canonical_energy_valley_dashboard_href() -> String {
  canonical_energy_valley_href() + "&panel=dashboard"
}

///|
fn canonical_energy_valley_module_href(module_id : String) -> String {
  canonical_energy_valley_href() + "&module=\{module_id}"
}

///|
fn energy_valley_dashboard_requested(panel : String) -> Bool {
  panel == "dashboard"
}
