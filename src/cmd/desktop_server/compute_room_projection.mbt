///|
/// Read-only infrastructure projection for MoonTown's secret compute room.
/// It deliberately exposes aliases and capacity summaries, never node
/// addresses, credentials, runtime paths, or provider secrets.
const COMPUTE_ROOM_SCHEMA = "moontown.secret-compute-room.v1"

///|
fn compute_room_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(value)) if !value.trim().is_empty() =>
      Some(value.trim().to_owned())
    _ => None
  }
}

///|
fn compute_room_int(obj : Map[String, Json], key : String) -> Int {
  match obj.get(key) {
    Some(Number(value, ..)) => value.to_int()
    Some(String(value)) => @string.parse_int(value) catch { _ => 0 }
    _ => 0
  }
}

///|
fn lunanexa_projection_endpoint_allowed(endpoint : String) -> Bool {
  let normalized = endpoint.trim().to_lower()
  normalized.has_prefix("https://") ||
  normalized.has_prefix("http://127.0.0.1:") ||
  normalized.has_prefix("http://localhost:")
}

///|
async fn lunanexa_heartbeat_json() -> Json? {
  guard env_value("MOONTOWN_LUNANEXA_ENDPOINT") is Some(endpoint) &&
    env_value("MOONTOWN_LUNANEXA_OPERATOR_TOKEN") is Some(token) &&
    lunanexa_projection_endpoint_allowed(endpoint) else {
    return None
  }
  let base = endpoint.trim().to_owned()
  let url = if base.has_suffix("/") {
    base + "v1/nodes"
  } else {
    base + "/v1/nodes"
  }
  let client = @http.Client(url, headers={
    "Authorization": "Bearer " + token,
    "Accept": "application/json",
  }) catch {
    _ => return None
  }
  defer client.close()
  let response = client.get("") catch { _ => return None }
  guard response.code == 200 else { return None }
  let text = client.read_all().text() catch { _ => return None }
  Some(@json.parse(text) catch { _ => return None })
}

///|
fn redacted_lunanexa_machines(source : Json?) -> Array[Json] {
  guard source is Some(Array(rows)) else { return [] }
  let machines : Array[Json] = []
  for index, row in rows {
    guard row is Object(heartbeat) else { continue }
    let state = compute_room_string(heartbeat, "state").unwrap_or("Unknown")
    let observed_at = compute_room_string(heartbeat, "timestamp_unix_ms").unwrap_or(
      "",
    )
    guard heartbeat.get("inventory") is Some(Object(inventory)) else {
      continue
    }
    let accelerators = match inventory.get("accelerators") {
      Some(Array(values)) => values
      _ => []
    }
    let mut memory_total_mib = 0
    let mut memory_free_mib = 0
    let mut healthy = !accelerators.is_empty()
    let mut architecture = "unreported"
    for accelerator in accelerators {
      guard accelerator is Object(device) else { continue }
      memory_total_mib += compute_room_int(device, "memory_total_mib")
      memory_free_mib += compute_room_int(device, "memory_free_mib")
      if architecture == "unreported" {
        architecture = compute_room_string(device, "architecture").unwrap_or(
          "unreported",
        )
      }
      match device.get("healthy") {
        Some(False) => healthy = false
        _ => ()
      }
    }
    let running = match heartbeat.get("running_deployments") {
      Some(Array(values)) => values.length()
      _ => 0
    }
    machines.push({
      "id": "local-node-\{index + 1}",
      "label": "Local node \{index + 1}",
      "state": if healthy {
        state
      } else {
        "Unhealthy"
      },
      "architecture": architecture,
      "accelerator_count": accelerators.length(),
      "memory_total_mib": memory_total_mib,
      "memory_free_mib": memory_free_mib,
      "healthy": healthy,
      "running_workloads": running,
      "observed_at_unix_ms": observed_at,
    })
  }
  machines
}

///|
fn moongate_active_targets(status : Json?) -> Array[Json] {
  guard status is Some(Object(obj)) &&
    obj.get("active_targets") is Some(Array(rows)) else {
    return []
  }
  rows.map(row => {
    guard row is Object(target) else {
      return { "app_type": "unknown", "provider_label": "Unreported route" }
    }
    {
      "app_type": compute_room_string(target, "app_type").unwrap_or("unknown"),
      "provider_label": compute_room_string(target, "provider_name").unwrap_or(
        "Configured provider",
      ),
    }
  })
}

///|
fn compute_room_route_observed(
  tokens : Array[String],
  status : Json?,
  models : Array[@moongate.MoonGateModel],
) -> Bool {
  let haystacks : Array[String] = []
  for target in moongate_active_targets(status) {
    haystacks.push(target.stringify().to_lower())
  }
  for model in models {
    haystacks.push(model.id.to_lower())
    match model.owner {
      Some(owner) => haystacks.push(owner.to_lower())
      None => ()
    }
  }
  tokens.any(token => haystacks.any(value => value.contains(token)))
}

///|
fn compute_room_remote_routes(
  moongate_live : Bool,
  status : Json?,
  models : Array[@moongate.MoonGateModel],
) -> Array[Json] {
  let definitions : Array[(String, String, Array[String])] = [
    ("codex", "Codex / OpenAI", ["codex", "openai", "gpt-"]),
    ("deepseek", "DeepSeek", ["deepseek"]),
    ("glm", "GLM", ["glm", "zhipu", "bigmodel"]),
    ("kimi", "Kimi", ["kimi", "moonshot"]),
  ]
  definitions.map(definition => {
    let observed = moongate_live &&
      compute_room_route_observed(definition.2, status, models)
    {
      "id": definition.0,
      "label": definition.1,
      "state": if observed {
        "observed"
      } else {
        "not-observed"
      },
      "evidence": if observed {
        "MoonGate reports a matching active target or model."
      } else if moongate_live {
        "MoonGate is reachable; this route has not been observed."
      } else {
        "MoonGate is not reachable from this MoonTown service."
      },
    }
  })
}

///|
async fn secret_compute_room_projection() -> Json {
  let client = @moongate.discover()
  let status = match client.status() {
    Ok(value) => Some(value)
    Err(_) => None
  }
  let models = match client.model_catalog() {
    Ok(values) => values
    Err(_) => []
  }
  let moongate_live = status is Some(_)
  let machines = redacted_lunanexa_machines(lunanexa_heartbeat_json())
  let cluster_configured = env_value("MOONTOWN_LUNANEXA_ENDPOINT") is Some(_)
  {
    "schema": COMPUTE_ROOM_SCHEMA,
    "mode": if moongate_live || !machines.is_empty() {
      "observed"
    } else {
      "unavailable"
    },
    "observed_at": iso_timestamp(@env.now()),
    "authority": {
      "agent_boundary": "MoonGate",
      "local_control_plane": "LunaNexa",
      "claim": "read-only redacted projection",
    },
    "gateway": {
      "state": if moongate_live {
        "reachable"
      } else {
        "unreachable"
      },
      "active_targets": moongate_active_targets(status),
      "model_count": models.length(),
    },
    "local_cluster": {
      "configured": cluster_configured,
      "state": if !machines.is_empty() {
        "observed"
      } else if cluster_configured {
        "unavailable"
      } else {
        "not-configured"
      },
      "machines": machines,
    },
    "remote_routes": compute_room_remote_routes(moongate_live, status, models),
  }
}
