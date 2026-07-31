///|
struct MoonFlowResearchExecutionRequest {
  contract_version : String
  intake : Json
} derive(FromJson)

///|
fn moonflow_research_execution_request_version(action : String) -> String {
  "moontown.moonflow-research-\{action}.request.v1"
}

///|
fn moonflow_research_execution_reply_version() -> String {
  "moontown.moonflow-research-execution.reply.v1"
}

///|
fn safe_loopback_research_result_url(url : String) -> Bool {
  let suffix = "/api/v1/moontown/result"
  if !url.has_suffix(suffix) {
    return false
  }
  safe_loopback_research_handoff_url(
    url[:url.length() - suffix.length()].to_owned() + "/api/v1/moontown/handoff",
  )
}

///|
fn configured_moonfind_result_url() -> String raise {
  let url = env_value("MOONTOWN_MOONFIND_CALLBACK_URL").unwrap_or(
    "http://127.0.0.1:4313/api/v1/moontown/result",
  )
  guard safe_loopback_research_result_url(url) else {
    fail(
      "MOONTOWN_MOONFIND_CALLBACK_URL must be an exact HTTP loopback /api/v1/moontown/result endpoint on a separate service",
    )
  }
  url
}

///|
fn moonflow_research_execution_reply(
  ok : Bool,
  action : String,
  execution_status : String,
  review_status : String,
  callback_status : String,
  callback_http_status : Int,
  handoff_id : String,
  result_package : Json?,
  receiver_receipt : Json?,
  error : String,
) -> Json {
  {
    "contract_version": moonflow_research_execution_reply_version(),
    "ok": ok,
    "action": action,
    "execution_status": execution_status,
    "review_status": review_status,
    "callback_status": callback_status,
    "callback_http_status": callback_http_status,
    "handoff_id": handoff_id,
    "package": result_package.unwrap_or(Json::null()),
    "receiver_receipt": receiver_receipt.unwrap_or(Json::null()),
    "error": error,
  }
}

///|
async fn run_moonflow_research_action(
  raw : String,
  action : String,
) -> Json noraise {
  let request : MoonFlowResearchExecutionRequest = @json.from_json(
    @json.parse(raw),
  ) catch {
    _ =>
      return moonflow_research_execution_reply(
        false,
        action,
        "blocked",
        "blocked",
        "not-attempted",
        0,
        "",
        None,
        None,
        "MoonTown received an invalid MoonFlow research execution request.",
      )
  }
  if request.contract_version !=
    moonflow_research_execution_request_version(action) ||
    !(action == "start" || action == "reconcile") {
    return moonflow_research_execution_reply(
      false,
      action,
      "blocked",
      "blocked",
      "not-attempted",
      0,
      "",
      None,
      None,
      "MoonTown received an unsupported MoonFlow research execution contract.",
    )
  }
  try {
    let workspace = @storage.moontown_active_workspace_root()
    let handoff = @flow_adapter.moonflow_research_handoff(
      workspace,
      request.intake,
    )
    guard handoff is Object(handoff_fields) else {
      fail("MoonTown MoonFlow input handoff is malformed")
    }
    let handoff_id = json_string_field(handoff_fields, "handoff_id")
    let recorded_at = iso_timestamp(@async.now().reinterpret_as_uint64())
    let result_package = if action == "start" {
      @flow_adapter.execute_research_handoff(workspace, handoff, recorded_at)
    } else {
      @flow_adapter.reconcile_research_handoff(workspace, handoff, recorded_at)
    }
    let (execution_status, review_status) = research_handoff_package_status(
      result_package,
    )
    if execution_status != "completed" || review_status != "pending" {
      return moonflow_research_execution_reply(
        true,
        action,
        execution_status,
        review_status,
        "not-deliverable",
        0,
        handoff_id,
        Some(result_package),
        None,
        "MoonTown persisted a non-completed result. Neither MoonFind nor MoonFlow was settled.",
      )
    }
    let callback = configured_moonfind_result_url()
    let (callback_status, callback_http_status, delivery_error) = deliver_research_handoff_result(
      callback, result_package,
    )
    if callback_status != "delivered" {
      return moonflow_research_execution_reply(
        false,
        action,
        execution_status,
        review_status,
        callback_status,
        callback_http_status,
        handoff_id,
        Some(result_package),
        None,
        delivery_error,
      )
    }
    let receiver_receipt = @flow_adapter.prepare_moonflow_research_receipt(
      workspace,
      request.intake,
      result_package,
      callback_http_status,
      recorded_at,
    )
    moonflow_research_execution_reply(
      true,
      action,
      execution_status,
      review_status,
      callback_status,
      callback_http_status,
      handoff_id,
      Some(result_package),
      Some(receiver_receipt),
      "",
    )
  } catch {
    error =>
      moonflow_research_execution_reply(
        false,
        action,
        "blocked",
        "blocked",
        "not-attempted",
        0,
        "",
        None,
        None,
        "\{error}",
      )
  }
}
