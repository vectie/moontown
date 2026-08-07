///|
test "idle and offline Agents never become authoritative presences or sprites" {
  let base = runtime_map_routing_live_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  for status in ["idle", "offline"] {
    let model = {
      ..base,
      energy_valley_runtime: {
        ..base.energy_valley_runtime,
        projection: Some({
          ..projection
          // The task remains active on purpose: Agent state must still veto
          // both presentation and semantic presence claims.
          ,
          tasks: [{ ..projection.tasks[0], status: "running" }],
          agents: [{ ..projection.agents[0], status, }],
        }),
      },
    }
    assert_true(
      energy_valley_runtime_active_agents(model.energy_valley_runtime).is_empty(),
    )
    let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
    assert_true(
      snapshot.actor_presences.all(presence => {
        presence.provenance.kind != @energy_valley_contract.RuntimeProjection
      }),
    )
    let sprites = town_snapshot_canvas_agents(snapshot, 0.0, false, None)
    assert_true(sprites.all(sprite => sprite.preview))
    assert_true(
      golden_valley_runtime_agent_map_positions_from_snapshot(
        snapshot,
        None,
        1280,
        720,
      ).is_empty(),
    )
  }
}
