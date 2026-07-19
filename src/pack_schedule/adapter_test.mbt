///|
test "projection registers schedules without domain branching" {
  let projection : @host.HostActivationProjection = {
    contract: "moonsuite.pack-host-activation.v1",
    pack_id: "fixture",
    product_id: "fixture",
    version: "1.0.0",
    required_runtime_extensions: [],
    book_templates: [],
    tools: [],
    schedules: [
      {
        id: "fixture.daily",
        cadence: "0 8 * * *",
        timezone: "Asia/Shanghai",
        workflow_id: "fixture.workflow",
      },
    ],
    app_entrypoints: [],
    provider_ports: [],
    policies: [],
  }
  let projected = bindings(projection)
  guard resolve(projected, "fixture.daily") is Some(binding) else {
    fail("schedule should resolve")
  }
  assert_eq(binding.workflow_id, "fixture.workflow")
  assert_eq(binding.pack_id, "fixture")
  let once = reconcile(empty_registry(), projection)
  let twice = reconcile(once, projection)
  assert_eq(twice.schedules.length(), 1)
  assert_eq(remove_pack(twice, "fixture").schedules.length(), 0)
}
