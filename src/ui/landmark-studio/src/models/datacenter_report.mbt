///|
/// Deterministic planning arithmetic, deliberately separate from observations.
/// Input is a workload scenario percentage, not measured CPU utilization.
pub fn data_center_report(load_percent : Int) -> Json {
  let load = load_percent.clamp(min=0, max=100)
  let server_w = 180.0 + 420.0 * load.to_double() / 100.0
  let rack_kw = (server_w * 12.0 + 120.0) / 1000.0
  {
    "schema": "moontown.datacenter-planning-report.v1",
    "mode": "illustrative-planning",
    "load_percent": load,
    "racks": 12,
    "servers": 144,
    "switches": 24,
    "rack_units_total": 504,
    "rack_units_used": 312,
    "rack_units_free": 192,
    "rack_kw": rack_kw,
    "it_kw": rack_kw * 12.0,
    "capacity_kw": 96,
    "headroom_kw": 96.0 - rack_kw * 12.0,
    "per_server_w": server_w,
    "pue": Json::null(),
    "temperature_c": Json::null(),
    "network_gbps": Json::null(),
    "assumptions": [
      "12 racks × 12 two-unit servers; two 1U leaf switches per rack", "Server planning power = 180 W + 420 W × workload scenario fraction",
      "Each rack adds 120 W for its two leaf switches; IT capacity = 8 kW per rack",
      "Spine, cooling, UPS losses and ancillary facility loads are not included",
      "No measured time series, rack placement, temperature, throughput or facility energy",
      "PUE withheld: requires matched facility / IT energy measurements and a stated period",
    ],
  }
}

///|
priv struct DcAuthority {
  agent_boundary : String
  local_control_plane : String
} derive(FromJson)

///|
priv struct DcMachine {
  id : String
  label : String
  state : String
  architecture : String
  accelerator_count : Int
  memory_total_mib : Int
  memory_free_mib : Int
  healthy : Bool
  running_workloads : Int
  observed_at_unix_ms : String
} derive(FromJson, ToJson)

///|
priv struct DcCluster {
  state : String
  machines : Array[DcMachine]
} derive(FromJson)

///|
priv struct DcGateway {
  state : String
  model_count : Int
} derive(FromJson)

///|
priv struct DcRoute {
  id : String
  label : String
  state : String
  evidence : String
} derive(FromJson, ToJson)

///|
priv struct DcProjection {
  schema : String
  mode : String
  observed_at : String
  authority : DcAuthority
  gateway : DcGateway
  local_cluster : DcCluster
  remote_routes : Array[DcRoute]
} derive(FromJson)

///|
/// Validate and project only approved fields; never echo arbitrary imported JSON.
/// This accepts the existing read-only MoonTown compute-room contract.
pub fn data_center_observation(text : String) -> Json {
  let invalid : Json = {
    "ok": false,
    "error": "Invalid or unsupported redacted compute-room snapshot",
  }
  if text.length() > 262144 {
    return invalid
  }
  let raw = @json.parse(text) catch { _ => return invalid }
  let snapshot : DcProjection = @json.from_json(raw) catch {
    _ => return invalid
  }
  if snapshot.schema != "moontown.secret-compute-room.v1" ||
    snapshot.authority.agent_boundary != "MoonGate" ||
    snapshot.authority.local_control_plane != "LunaNexa" ||
    !(snapshot.mode == "observed" || snapshot.mode == "unavailable") ||
    snapshot.local_cluster.machines.length() > 64 ||
    snapshot.remote_routes.length() > 16 ||
    snapshot.gateway.model_count < 0 ||
    snapshot.observed_at.length() > 64 {
    return invalid
  }
  let machines = snapshot.local_cluster.machines
  let seen : Map[String, Bool] = Map([])
  for m in machines {
    if m.id.is_empty() ||
      m.id.length() > 80 ||
      seen.contains(m.id) ||
      m.label.is_empty() ||
      m.label.length() > 160 ||
      m.state.length() > 80 ||
      m.architecture.length() > 160 ||
      m.observed_at_unix_ms.length() > 32 ||
      m.accelerator_count < 0 ||
      m.accelerator_count > 1024 ||
      m.running_workloads < 0 ||
      m.running_workloads > 1000000 ||
      m.memory_total_mib < 0 ||
      m.memory_free_mib < 0 ||
      m.memory_free_mib > m.memory_total_mib {
      return invalid
    }
    seen[m.id] = true
  }
  let route_ids : Map[String, Bool] = Map([])
  for r in snapshot.remote_routes {
    if r.id.is_empty() ||
      r.id.length() > 80 ||
      route_ids.contains(r.id) ||
      r.label.length() > 160 ||
      r.state.length() > 80 ||
      r.evidence.length() > 1000 {
      return invalid
    }
    route_ids[r.id] = true
  }
  {
    "ok": true,
    "schema": "moontown.datacenter-observation.v1",
    "mode": snapshot.mode,
    "observed_at": snapshot.observed_at,
    "gateway_state": snapshot.gateway.state,
    "model_count": snapshot.gateway.model_count,
    "cluster_state": snapshot.local_cluster.state,
    "machines": machines.to_json(),
    "remote_routes": snapshot.remote_routes.to_json(),
    "physical_mapping": "unassigned",
    "sensor_coverage": "No power, thermal, network counters or rack locations in this contract",
  }
}
