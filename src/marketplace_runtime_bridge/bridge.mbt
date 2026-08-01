///| The host/mini-app adapter shared by both MoonTown entrypoints. It joins the

///| generic supervisor receipt stream to marketplace request state without

///| putting marketplace concepts into MoonClaw or the supervisor kernel.

///|
fn object_fields(value : Json) -> Map[String, Json] raise {
  match value {
    Object(fields) => fields
    _ => fail("marketplace runtime bridge expected an object")
  }
}

///|
fn string_field(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
fn string_items(fields : Map[String, Json], key : String) -> Array[String] {
  match fields.get(key) {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(text) => Some(text)
          _ => None
        }
      })
    _ => []
  }
}

///|
fn application(
  state_path : String,
) -> @town_marketplace.MarketplaceApplication raise {
  @town_marketplace.marketplace_application(
    state_path,
    {
      principal_id: "moondesk-owner-service",
      tenant_id: "local-town",
      display_name: "MoonDesk owner service",
      workspace_ids: [],
      roles: ["publisher"],
      interest_tags: [],
      active: true,
      version: 1,
    },
    "bootstrap:moondesk-owner-service",
    "moondesk-owner-bootstrap-token",
  )
}

///|
fn execution_runtime_draft(
  request_body : String,
  supervisor_result : Json,
) -> @town_marketplace.ActionRequestRuntimeDraft raise {
  let request = object_fields(@json.parse(request_body))
  let result = object_fields(supervisor_result)
  let receipt = match request.get("receipt") {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  let worker = match receipt.get("worker") {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  let worker_status = string_field(worker, "execution_status")
  {
    handoff_id: string_field(result, "handoffId"),
    runtime_status: if worker_status.is_empty() {
      string_field(result, "status")
    } else {
      worker_status
    },
    worker_run_id: string_field(worker, "worker_run_id"),
    result_summary: string_field(worker, "summary"),
    result_evidence_refs: string_items(worker, "artifact_refs"),
  }
}

///|
pub async fn sync_execution_receipt(
  state_path : String,
  request_body : String,
  supervisor_result : Json,
  now_ms~ : UInt64,
) -> Json {
  application(state_path).reconcile_runtime_handoff(
    execution_runtime_draft(request_body, supervisor_result),
    now_ms~,
  )
}

///|
pub async fn sync_action_lineage(
  state_path : String,
  supervisor : @supervisor_setup.SupervisorSetupApplication,
  now_ms~ : UInt64,
) -> Json {
  let mut synced = 0
  for lineage in supervisor.execution_lineage_projection() {
    guard lineage is Object(fields) else { continue }
    let status = {
      let runtime = string_field(fields, "runtimeExecutionStatus")
      if runtime.is_empty() {
        string_field(fields, "status")
      } else {
        runtime
      }
    }
    let summary = match fields.get("summary") {
      Some(String(value)) => value
      _ =>
        match fields.get("error") {
          Some(String(value)) => value
          _ => ""
        }
    }
    let reconciled = application(state_path).reconcile_runtime_handoff(
      {
        handoff_id: string_field(fields, "handoffId"),
        runtime_status: status,
        worker_run_id: string_field(fields, "runId"),
        result_summary: summary,
        result_evidence_refs: string_items(fields, "artifactRefs"),
      },
      now_ms~,
    ) catch {
      _ => Json::null()
    }
    if reconciled != Json::null() {
      synced += 1
    }
  }
  { "ok": true, "synced": synced }
}
