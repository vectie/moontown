///|
async test "MoonFind handoff bridge reuses one Flow attempt and stays pending review" {
  let root = @fs.tmpdir(prefix="moontown-research-handoff-bridge")
  let fixture_scenario : @civic.CivicCommunicationScenario = @json.from_json(
    @json.parse(
      @fs.read_file("assets/templates/civic-salons/robotics-mini-salon.json").text(),
    ),
  )
  let scenario = {
    ..fixture_scenario,
    review_gate: "named-human",
    review_owner: "moonbook.bookkeeper",
  }
  let handoff : Json = {
    "contract_version": "moontown.civic.communication.handoff.v1",
    "handoff_id": "moonfind-bridge-test-research-salon",
    "producer": "moonfind",
    "producer_run_id": "bridge-test",
    "scenario": scenario.to_json(),
  }
  let plan = ensure_research_handoff_flow_plan(
    root, handoff, "2026-07-31T00:00:00Z", true,
  )
  let adapter_result = execute_with_mode(
    root,
    plan.request_ref,
    plan.result_ref,
    @civic.FixtureReducer,
  )
  let first = research_handoff_result_package(plan, adapter_result)
  let replay_plan = ensure_research_handoff_flow_plan(
    root, handoff, "2099-01-01T00:00:00Z", true,
  )
  let replay_result = execute_with_mode(
    root,
    replay_plan.request_ref,
    replay_plan.result_ref,
    @civic.FixtureReducer,
  )
  let replay = research_handoff_result_package(replay_plan, replay_result)
  assert_eq(first, replay)
  guard first is Object(fields) &&
    fields.get("receipt") is Some(Object(receipt)) &&
    fields.get("output") is Some(Object(output)) &&
    fields.get("source") is Some(Object(source)) else {
    fail("expected a correlated MoonFind result package")
  }
  assert_eq(
    json_string_field(fields, "contract_id"),
    "moonfind.moontown-result-ingest.v1",
  )
  assert_eq(json_string_field(receipt, "status"), "completed")
  assert_eq(json_string_field(receipt, "review_status"), "pending")
  assert_eq(
    json_string_field(output, "contract_id"),
    "civic.communication.output.v1",
  )
  assert_eq(json_string_field(source, "operation_ref"), operation_ref())
}
