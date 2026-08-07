///|
fn worker_roster_asset(index : Int) -> String {
  "tilemap/actors/roster/resident_\{index % 64}_walk_strip.png"
}

///|
/// Runtime profiles carry only the town's symbolic avatar allowlist. Resolve
/// those symbols to bundled assets; never evaluate a remote profile URL.
fn energy_valley_runtime_agent_sprite_asset(
  agent : EnergyValleyRuntimeAgent,
  index : Int,
) -> String {
  match agent.avatarRef {
    Some("avatar://otter-steward") => "tilemap/actors/keeper_walk_strip.png"
    Some("avatar://moon-lantern") => "tilemap/actors/researcher_walk_strip.png"
    _ =>
      if agent.role == "worker" {
        "tilemap/actors/worker_walk_strip.png"
      } else if agent.role == "keeper" {
        "tilemap/actors/keeper_walk_strip.png"
      } else {
        worker_roster_asset(index)
      }
  }
}
