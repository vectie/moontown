///|
fn module_workstation_test_runtime() -> EnergyValleyRuntimeState {
  energy_valley_runtime_state_from_text(
    (
      #|{
      #|  "schema": "moontown.energy-valley.runtime.v1",
      #|  "mode": "live",
      #|  "observedAt": "1970-01-01T00:01:40.000Z",
      #|  "knowledgeCatalogDigest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "tasks": [
      #|    {"id":"intake","title":"Intake","status":"queued","buildingModuleKey":"policy-hall","artifacts":[],"source":"operator-request"},
      #|    {"id":"discover","title":"Discover","status":"running","buildingModuleKey":"policy-hall","artifacts":[],"source":"watcher"},
      #|    {"id":"synthesize","title":"Synthesize","status":"running","buildingModuleKey":"policy-hall","artifacts":[],"progress":{"acceptedFacts":2},"source":"watcher"},
      #|    {"id":"review","title":"Review","status":"waiting_review","buildingModuleKey":"policy-hall","artifacts":[],"source":"town-runtime"},
      #|    {"id":"deliver","title":"Deliver","status":"completed","buildingModuleKey":"policy-hall","artifacts":["report"],"source":"town-runtime"},
      #|    {"id":"recover","title":"Recover","status":"blocked","buildingModuleKey":"policy-hall","artifacts":[],"source":"town-runtime"}
      #|  ],
      #|  "agents": []
      #|}
    ),
    1,
    110000.0,
  )
}

///|
test "procedural module work floor is deterministic and collision free" {
  let civic = wenyu_module_building_test_module()
  let first = module_interior_seed(civic)
  assert_eq(first, module_interior_seed(civic))
  let seen : Array[Bool] = [false, false, false, false, false, false]
  for index in 0..<6 {
    let slot = module_work_station_slot(civic, index)
    assert_true(slot >= 0 && slot < 6)
    assert_true(!seen[slot])
    seen[slot] = true
  }
}

///|
test "each live runtime task activates exactly one work station" {
  let civic = wenyu_module_building_test_module()
  let stations = module_work_stations(module_workstation_test_runtime(), civic)
  assert_eq(stations.length(), 6)
  assert_true(stations.all(station => station.count == 1))
  let mut total = 0
  for station in stations {
    total = total + station.count
  }
  assert_eq(total, 6)
}

///|
test "stale runtime preserves the snapshot without active station claims" {
  let civic = wenyu_module_building_test_module()
  let stale = energy_valley_runtime_state_at(
    module_workstation_test_runtime(),
    175000.0,
  )
  assert_true(stale.phase == Stale)
  let stations = module_work_stations(stale, civic)
  assert_true(stations.all(station => station.state == "stale"))
  assert_true(stations.all(station => station.count == 1))
  assert_true(
    stations.all(station => {
      module_work_station_state_label(station).has_prefix("Snapshot")
    }),
  )
}

///|
test "work floor keeps fixtures and concrete tasks behind disclosure" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_module_work_floor(
        wenyu_module_building_test_module(),
        module_workstation_test_runtime(),
      ),
    ),
  )
  assert_true(html.contains("Procedural work floor"))
  assert_true(html.contains("Recorded building work"))
  assert_true(html.contains("Synthesize"))
  assert_true(html.contains("Task ID"))
  assert_true(html.contains("<details"))
  assert_true(html.contains("Room fixtures"))
  assert_true(!html.contains("<details open"))
}

///|
test "agent exchange exposes real roster and collaboration evidence" {
  let runtime = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let civic = wenyu_module_building_test_module()
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_module_agent_exchange(runtime, civic),
    ),
  )
  assert_true(html.contains("Agent exchange"))
  assert_true(html.contains("Exchange active"))
  assert_true(html.contains("Scout"))
  assert_true(html.contains("Recorded collaboration families"))
  let stale_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_module_agent_exchange(
        energy_valley_runtime_state_at(runtime, 175000.0),
        civic,
      ),
    ),
  )
  assert_true(stale_html.contains("Last recorded exchange team"))
  assert_true(stale_html.contains("not presented as live activity"))
}
