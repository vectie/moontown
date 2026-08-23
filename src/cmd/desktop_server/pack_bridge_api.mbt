///|
fn pack_bridge_state_path() -> String {
  state_root() + "/pack-bridge/state.json"
}

///|
async fn pack_bridge_snapshot() -> Json {
  @pack_town_bridge_runtime.discover_active_packs(
    @storage.moontown_active_workspace_root(),
    pack_bridge_state_path(),
    iso_timestamp(@env.now()),
  ).to_json()
}

///|
async fn ingest_pack_bridge_projection(body : String) -> Json {
  @pack_town_bridge_runtime.ingest_projection(
    @storage.moontown_active_workspace_root(),
    pack_bridge_state_path(),
    @json.parse(body),
    iso_timestamp(@env.now()),
  ).to_json()
}

///|
async fn submit_pack_bridge_candidate(body : String) -> Json {
  @pack_town_bridge_runtime.submit_candidate(
    @storage.moontown_active_workspace_root(),
    pack_bridge_state_path(),
    @json.parse(body),
    iso_timestamp(@env.now()),
  ).to_json()
}
