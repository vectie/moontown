///|
const COMPUTE_ROOM_SCHEMA = "moontown.secret-compute-room.v1"

///| Shared identity is the only authority for customer compute. Never fall back

///|
/// to operator inventory or MoonGate's host-wide provider configuration.
fn account_compute_snapshot(
  state : String,
  machines : Array[Json],
  account : Json,
  organizations : Array[Json],
) -> Json {
  let scope = {
    "state": state.to_json(),
    "audience": "personal".to_json(),
    "organizations": organizations.to_json(),
  }
  if account is Object(_) {
    scope["account"] = account
  }
  {
    "schema": COMPUTE_ROOM_SCHEMA,
    "mode": if state == "bound" {
      "observed"
    } else {
      "unavailable"
    },
    "observed_at": iso_timestamp(@env.now()),
    "scope": Json::object(scope),
    "authority": {
      "agent_boundary": "MoonGate",
      "local_control_plane": "LunaNexa",
      "claim": "current account; subject-authorized resources only",
    },
    "gateway": {
      "state": "not-observed",
      "active_targets": [],
      "model_count": 0,
    },
    "local_cluster": {
      "configured": @account_identity.enabled(),
      "state": state,
      "machines": machines,
    },
    "remote_routes": [],
  }
}

///| This customer API deliberately does not disclose hardware inventory or

///|
/// utilization. Missing telemetry is unknown, never zero usage or free capacity.
fn account_compute_machines(value : Json) -> Array[Json]? {
  guard value is Array(rows) && rows.length() <= 64 else { return None }
  let machines : Array[Json] = []
  let ids : Map[String, Bool] = Map([])
  for row in rows {
    guard row
      is {
        "machine_ref": String(id),
        "lease_ref": String(lease),
        "state": String(lease_state),
        "reachability": String(reachability),
        ..
      } &&
      !id.is_empty() &&
      id.length() <= 256 &&
      !lease.is_empty() &&
      lease.length() <= 128 &&
      !ids.contains(id) else {
      return None
    }
    ids[id] = true
    if ["Completed", "Cancelled"].contains(lease_state) {
      continue
    }
    let state = if lease_state == "Active" {
      if reachability == "Online" {
        "ready"
      } else if reachability == "Delayed" {
        "delayed"
      } else {
        "unknown"
      }
    } else {
      lease_state
    }
    machines.push({
      "id": id,
      "label": "机器 · " +
      (if lease.length() > 8 {
        lease[lease.length() - 8:].to_owned()
      } else {
        lease
      }),
      "state": state,
      "architecture": "未提供硬件信息",
      "accelerator_count": 0,
      "memory_total_mib": 0,
      "memory_free_mib": 0,
      "healthy": state == "ready",
      "running_workloads": 0,
      "observed_at_unix_ms": "",
      "metrics_reported": false,
    })
  }
  Some(machines)
}

///|
fn account_compute_organizations(
  session : @account_identity.Session,
  value : Json,
) -> Array[Json] {
  guard value is { "organizations": Array(rows), .. } else { return [] }
  let choices : Array[Json] = []
  for row in rows {
    if choices.length() >= 64 {
      break
    }
    guard row
      is {
        "organization": {
          "organization_id": String(id),
          "display_name": String(name),
          ..
        },
        "membership": { "subject_ref": String(subject), "active": True, .. },
        ..
      } &&
      session.owns_subject(subject) &&
      !name.trim().is_empty() &&
      valid_compute_organization(id) else {
      continue
    }
    choices.push({ "id": id, "label": name })
  }
  choices
}

///|
fn valid_compute_organization(id : String) -> Bool {
  !id.is_empty() &&
  id.length() <= 128 &&
  id
  .iter()
  .all(c => {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '-' ||
    c == '_' ||
    c == '.' ||
    c == ':'
  })
}

///|
pub async fn read(cookie : String, organization : String) -> Json {
  let session = match @account_identity.resolve(cookie) {
    Authenticated(session) => session
    Disabled =>
      return account_compute_snapshot("not-configured", [], Json::null(), [])
    SignedOut =>
      return account_compute_snapshot("sign-in-required", [], Json::null(), [])
    Unavailable =>
      return account_compute_snapshot(
        "identity-unavailable",
        [],
        Json::null(),
        [],
      )
  }
  for_session(session, organization)
}

///|
/// Works without a model or workspace. Workspace callers additionally pin the
/// organization; the shared front door lets the self API validate membership.
pub async fn for_session(
  session : @account_identity.Session,
  organization : String,
) -> Json {
  let account = @account_system.account_context_projection(session.context())
  if !organization.is_empty() && !valid_compute_organization(organization) {
    return account_compute_snapshot("access-denied", [], account, [])
  }
  let (code, value) = session.read_self("/v1/machine-access/self", organization)
  if code == 200 {
    return match account_compute_machines(value) {
      Some(machines) => account_compute_snapshot("bound", machines, account, [])
      None => account_compute_snapshot("unavailable", [], account, [])
    }
  }
  if code == 409 &&
    value
    is { "error": { "code": String("OrganizationSelectionRequired"), .. }, .. } {
    let (status, choices) = session.read_self(
      "/v1/portal/self/organizations", "",
    )
    return account_compute_snapshot(
      "select-organization",
      [],
      account,
      if status == 200 {
        account_compute_organizations(session, choices)
      } else {
        []
      },
    )
  }
  account_compute_snapshot(
    if code == 401 {
      "sign-in-required"
    } else if code == 403 || code == 404 {
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
    [],
  )
}

///|
fn iso_timestamp(timestamp_ms : UInt64) -> String {
  let value = @time.PlainDateTime::from_unix_second(
    (timestamp_ms / 1000UL).reinterpret_as_int64(),
    (timestamp_ms % 1000UL).to_int() * 1000000,
    @time.utc_offset,
  ) catch {
    _ => return ""
  }
  value.to_string() + "Z"
}
