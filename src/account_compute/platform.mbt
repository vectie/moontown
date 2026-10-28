///|
/// The approved town fleet, not every Kubernetes node. Node IDs never become
/// public resource IDs. Keep the public trial pair separate from owned leases.
fn town_fleet() -> Array[(String, String, String)] {
  [
    ("spark-25e2-3d35c8fd", "trial-01", "Trial · 01"),
    ("spark-3782-feee26eb", "trial-02", "Trial · 02"),
    ("spark-57f5-98a504ed", "dedicated-01", "独占 · 01"),
    ("spark-368c-0f2ee8b2", "dedicated-02", "独占 · 02"),
  ]
}

///|
fn catalog_machine(id : String, label : String) -> Json {
  {
    "id": id,
    "label": label,
    "state": "not-observed",
    "architecture": "未同步硬件信息",
    "accelerator_count": 0,
    "memory_total_mib": 0,
    "memory_free_mib": 0,
    "healthy": false,
    "running_workloads": 0,
    "observed_at_unix_ms": "",
    "metrics_reported": false,
  }
}

///|
fn platform_snapshot(
  audience : String,
  state : String,
  machines : Array[Json],
  account : Json,
) -> Json {
  guard account_compute_snapshot(state, machines, account, []) is Object(fields) else {
    abort("snapshot must be object")
  }
  guard fields["scope"] is Object(scope) else { abort("scope must be object") }
  scope["audience"] = audience.to_json()
  if audience == "public" {
    fields["mode"] = "demo".to_json()
    fields["observed_at"] = "".to_json()
    fields["authority"] = {
      "agent_boundary": "MoonGate",
      "local_control_plane": "LunaNexa",
      "claim": "public trial catalog; town agents are demonstration, not live workloads",
    }
  }
  Json::object(fields)
}

///|
/// Anonymous visitors get a curated catalog, never a controller inventory or
/// a customer lease. Zero-valued legacy numeric fields are explicitly unknown.
pub fn public_demo() -> Json {
  platform_snapshot(
    "public",
    "public-demo",
    town_fleet()[:2].map(entry => catalog_machine(entry.1, entry.2)),
    Json::null(),
  )
}

///|
priv struct FleetAccelerator {
  architecture : String
  memory_total_mib : Int32
  memory_free_mib : Int32
  healthy : Bool
} derive(FromJson)

///|
priv struct FleetHeartbeat {
  node_id : String
  state : String
  timestamp_unix_ms : Int64
  inventory : FleetInventory
  running_deployments : Array[String]
} derive(FromJson)

///|
priv struct FleetInventory {
  accelerators : Array[FleetAccelerator]
} derive(FromJson)

///|
fn fleet_machines(value : Json, now : Int64) -> Array[Json]? {
  guard value is Array(rows) && rows.length() <= 1024 else { return None }
  let known : Map[String, FleetHeartbeat] = {}
  let fleet = town_fleet()
  for row in rows {
    guard row is { "node_id": String(id), .. } else { return None }
    if !fleet.any(entry => entry.0 == id) {
      continue
    }
    let heartbeat : FleetHeartbeat = @json.from_json(row) catch {
      _ => return None
    }
    if known.contains(id) ||
      heartbeat.inventory.accelerators.length() > 16 ||
      !heartbeat.inventory.accelerators.all(a => {
        a.memory_total_mib >= 0 &&
        a.memory_total_mib <= 16777216 &&
        a.memory_free_mib >= 0 &&
        a.memory_free_mib <= a.memory_total_mib
      }) {
      return None
    }
    known[id] = heartbeat
  }
  Some(
    fleet.map(entry => {
      guard known.get(entry.0) is Some(node) else {
        return catalog_machine(entry.1, entry.2)
      }
      let fresh = node.timestamp_unix_ms > 0L &&
        node.timestamp_unix_ms <= now + 5000L &&
        now - node.timestamp_unix_ms <= 90000L
      let accelerators = node.inventory.accelerators
      let healthy = fresh &&
        !accelerators.is_empty() &&
        accelerators.all(a => a.healthy)
      {
        "id": entry.1,
        "label": entry.2,
        "state": if !fresh {
          "delayed"
        } else {
          node.state.to_lower()
        },
        "architecture": accelerators.map(a => a.architecture).join(", "),
        "accelerator_count": accelerators.length(),
        "memory_total_mib": accelerators.fold(init=0, (sum, a) => {
          sum + a.memory_total_mib
        }),
        "memory_free_mib": if fresh {
          accelerators.fold(init=0, (sum, a) => sum + a.memory_free_mib)
        } else {
          0
        },
        "healthy": healthy,
        "running_workloads": if fresh {
          node.running_deployments.length()
        } else {
          0
        },
        "observed_at_unix_ms": node.timestamp_unix_ms.to_string(),
        "metrics_reported": fresh && !accelerators.is_empty(),
      }
    }),
  )
}

///|
pub async fn platform_for_session(
  session : @account_identity.Session,
  endpoint : String,
  ca_file : String,
) -> Json {
  let account = @account_system.account_context_projection(session.context())
  guard session.is_platform_operator() else {
    return platform_snapshot("personal", "access-denied", [], account)
  }
  let (code, value) = session.read_platform_nodes(endpoint, ca_file)
  if code == 200 &&
    fleet_machines(value, @env.now().reinterpret_as_int64()) is Some(machines) {
    return platform_snapshot("admin", "bound", machines, account)
  }
  platform_snapshot(
    "admin",
    if code == 401 {
      "sign-in-required"
    } else if code == 403 {
      "access-denied"
    } else {
      "unavailable"
    },
    [],
    if code == 401 {
      Json::null()
    } else {
      account
    },
  )
}
