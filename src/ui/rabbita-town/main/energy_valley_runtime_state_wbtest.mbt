///|
fn energy_valley_runtime_test_projection_text(
  observed_at : String,
  mode : String,
) -> String {
  let template =
    #|{
    #|  "schema": "moontown.energy-valley.runtime.v1",
    #|  "mode": "__MODE__",
    #|  "observedAt": "__OBSERVED_AT__",
    #|  "knowledgeCatalogDigest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    #|  "tick": 42,
    #|  "tasks": [{
    #|    "id": "research-task",
    #|    "title": "Collaborated research",
    #|    "status": "running",
    #|    "buildingModuleKey": "policy-hall",
    #|    "agentId": "agent-1",
    #|    "agentName": "Scout",
    #|    "role": "worker",
    #|    "runId": "run-parent",
    #|    "bookId": "policy-hall",
    #|    "requestId": "request-1",
    #|    "correlationId": "request-1",
    #|    "artifacts": ["report.md"],
    #|    "resultLinks": [{"label":"Report","url":"/book-output/policy-hall/report.html","kind":"report"}],
    #|    "collaboration": {
    #|      "mode": "parallel",
    #|      "participants": [{"runId":"run-child","family":"source-review","status":"completed","artifacts":["sources.json"]}]
    #|    },
    #|    "progress": {"checkedSources":8,"acceptedFacts":3,"bookChanged":true},
    #|    "source": "operator-request"
    #|  }],
    #|  "agents": [{
    #|    "id": "agent-1",
    #|    "name": "Scout",
    #|    "role": "worker",
    #|    "status": "running",
    #|    "buildingModuleKey": "policy-hall",
    #|    "workItemId": "research-task",
    #|    "runId": "run-parent"
    #|  }]
    #|}
  template
  .replace(old="__MODE__", new=mode)
  .replace(old="__OBSERVED_AT__", new=observed_at)
}

///|
test "runtime v1 FromJson keeps task collaboration and result evidence" {
  let state = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    3,
    110000.0,
  )
  assert_true(state.phase == Live)
  let projection = state.projection.unwrap()
  assert_eq(projection.tick, Some(42))
  assert_eq(projection.tasks[0].id, "research-task")
  assert_eq(projection.tasks[0].runId, Some("run-parent"))
  assert_eq(projection.tasks[0].correlationId, Some("request-1"))
  assert_eq(
    projection.tasks[0].collaboration.unwrap().participants[0].runId,
    "run-child",
  )
  assert_eq(
    projection.tasks[0].resultLinks.unwrap()[0].url,
    "/book-output/policy-hall/report.html",
  )
}

///|
test "runtime freshness becomes stale at 75 seconds and suppresses active claims" {
  let live = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  assert_true(energy_valley_runtime_can_claim_active_work(live))
  let still_live = energy_valley_runtime_state_at(live, 174999.0)
  assert_true(still_live.phase == Live)
  let stale = energy_valley_runtime_state_at(live, 175000.0)
  assert_true(stale.phase == Stale)
  assert_true(!energy_valley_runtime_can_claim_active_work(stale))
}

///|
test "unavailable and invalid runtime states never claim active work" {
  let unavailable = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "unavailable",
    ),
    1,
    110000.0,
  )
  assert_true(unavailable.phase == Unavailable)
  assert_true(!energy_valley_runtime_can_claim_active_work(unavailable))
  let malformed = energy_valley_runtime_state_from_text("{", 2, 110000.0)
  assert_true(malformed.phase == Error)
  assert_true(!energy_valley_runtime_can_claim_active_work(malformed))
  assert_true(
    !energy_valley_runtime_result_url_is_safe(
      "/book-output/policy-hall/%252e%252e/private",
    ),
  )
}

///|
test "runtime building lens exposes auditable work behind disclosure" {
  let state = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_module_work_lens(
        state,
        wenyu_module_building_test_module(),
      ),
    ),
  )
  assert_true(html.contains("research-task"))
  assert_true(html.contains("run-parent"))
  assert_true(html.contains("request-1"))
  assert_true(html.contains("run-child"))
  assert_true(html.contains("/book-output/policy-hall/report.html"))
  assert_true(html.contains("<details"))
  assert_true(!html.contains("<details open"))
}

///|
test "runtime research work resolves to a concrete Energy Valley lab" {
  let state = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let base_task = state.projection.unwrap().tasks[0]
  let civic = {
    ..wenyu_module_building_test_module(),
    id: "research-ai-agents",
    book_id: "research-ai-agents",
  }
  assert_true(
    energy_valley_runtime_task_matches_module(
      {
        ..base_task,
        buildingModuleKey: "research-ai-agents",
        bookId: Some("research-agent-work-projection"),
      },
      civic,
    ),
  )
  assert_true(
    energy_valley_runtime_task_matches_module(
      {
        ..base_task,
        buildingModuleKey: "energy-lab",
        bookId: Some("research-agent-work-projection"),
      },
      civic,
    ),
  )
}
