///|
struct ResearchHandoffExecutionRequest {
  contract_version : String
  handoff_url : String
  expected_contract : String
  expected_handoff_id : String
} derive(FromJson)

///|
fn research_handoff_execution_request_version(action : String) -> String {
  "moontown.research-handoff-\{action}.request.v1"
}

///|
fn research_handoff_execution_reply_version() -> String {
  "moontown.research-handoff-execution.reply.v1"
}

///|
fn research_handoff_callback_url(handoff_url : String) -> String raise {
  guard safe_loopback_research_handoff_url(handoff_url) else {
    fail("MoonTown cannot derive a callback from an unsafe handoff URL")
  }
  let suffix = "/api/v1/moontown/handoff"
  handoff_url[:handoff_url.length() - suffix.length()].to_owned() +
  "/api/v1/moontown/result"
}

///|
fn research_handoff_execution_reply(
  ok : Bool,
  action : String,
  request : ResearchHandoffExecutionRequest?,
  execution_status : String,
  review_status : String,
  callback_status : String,
  callback_http_status : Int,
  result_package : Json?,
  error : String,
) -> Json {
  {
    "contract_version": research_handoff_execution_reply_version(),
    "ok": ok,
    "action": action,
    "requested_url": request.map(value => value.handoff_url).unwrap_or(""),
    "handoff_id": request.map(value => value.expected_handoff_id).unwrap_or(""),
    "execution_status": execution_status,
    "review_status": review_status,
    "callback_status": callback_status,
    "callback_http_status": callback_http_status,
    "package": result_package.unwrap_or(Json::null()),
    "error": error,
  }
}

///|
fn inspected_handoff_from_reply(
  request : ResearchHandoffExecutionRequest,
  reply : Json,
) -> Json raise {
  guard reply is Object(fields) &&
    json_string_field(fields, "contract_version") ==
    research_handoff_inspection_reply_version() &&
    fields.get("ok") is Some(True) &&
    json_string_field(fields, "requested_url") == request.handoff_url &&
    fields.get("handoff") is Some(handoff) &&
    !(handoff is Null) else {
    let detail = match reply {
      Object(fields) => json_string_field(fields, "error")
      _ => ""
    }
    fail(
      if detail.is_blank() {
        "MoonTown could not revalidate the exact handoff before execution"
      } else {
        detail
      },
    )
  }
  handoff
}

///|
fn research_handoff_package_status(
  result_package : Json,
) -> (String, String) raise {
  guard result_package is Object(fields) &&
    json_string_field(fields, "contract_id") ==
    "moonfind.moontown-result-ingest.v1" &&
    fields.get("receipt") is Some(Object(receipt)) else {
    fail("MoonTown Flow returned an unsupported result package")
  }
  (
    json_string_field(receipt, "status"),
    json_string_field(receipt, "review_status"),
  )
}

///|
fn research_handoff_callback_payload(
  result_package : Json,
) -> (Bytes, Map[String, String]) {
  let encoded = @utf8.encode(result_package.stringify())
  (
    encoded,
    {
      "Content-Type": "application/json; charset=utf-8",
      "Accept": "application/json",
      "Content-Length": encoded.length().to_string(),
    },
  )
}

///|
async fn deliver_research_handoff_result(
  callback_url : String,
  result_package : Json,
) -> (String, Int, String) {
  try {
    let (payload, headers) = research_handoff_callback_payload(result_package)
    let client = @http.post_stream(callback_url, headers~)
    defer client.close()
    client.write(payload)
    let response = client.end_request()
    let data = client.read_all()
    let text = data.text()
    if response.code >= 200 && response.code < 300 {
      ("delivered", response.code, "")
    } else {
      (
        "pending-reconcile",
        response.code,
        "MoonFind rejected the correlated result with HTTP \{response.code}: \{text}",
      )
    }
  } catch {
    error =>
      (
        "pending-reconcile",
        0,
        "MoonTown retained the result, but delivery to MoonFind failed: \{error}",
      )
  }
}

///|
async fn run_research_handoff_action(
  raw : String,
  action : String,
) -> Json noraise {
  let request : ResearchHandoffExecutionRequest = @json.from_json(
    @json.parse(raw),
  ) catch {
    _ =>
      return research_handoff_execution_reply(
        false,
        action,
        None,
        "blocked",
        "blocked",
        "not-attempted",
        0,
        None,
        "MoonTown received an invalid research-handoff execution request.",
      )
  }
  if request.contract_version !=
    research_handoff_execution_request_version(action) ||
    request.expected_contract != civic_research_handoff_version() ||
    request.expected_handoff_id.is_blank() {
    return research_handoff_execution_reply(
      false,
      action,
      Some(request),
      "blocked",
      "blocked",
      "not-attempted",
      0,
      None,
      "The execution request contract or expected handoff identity is invalid.",
    )
  }
  try {
    let inspection_request : Json = {
      "contract_version": research_handoff_inspection_request_version(),
      "handoff_url": request.handoff_url,
      "expected_contract": request.expected_contract,
      "expected_handoff_id": request.expected_handoff_id,
    }
    let inspection = inspect_research_handoff(inspection_request.stringify())
    let handoff = inspected_handoff_from_reply(request, inspection)
    let workspace = @storage.moontown_active_workspace_root()
    let result_package = if action == "start" {
      @flow_adapter.execute_research_handoff(
        workspace,
        handoff,
        iso_timestamp(@async.now().reinterpret_as_uint64()),
      )
    } else {
      @flow_adapter.reconcile_research_handoff(
        workspace,
        handoff,
        iso_timestamp(@async.now().reinterpret_as_uint64()),
      )
    }
    let (execution_status, review_status) = research_handoff_package_status(
      result_package,
    )
    if execution_status != "completed" || review_status != "pending" {
      return research_handoff_execution_reply(
        true,
        action,
        Some(request),
        execution_status,
        review_status,
        "not-deliverable",
        0,
        Some(result_package),
        "MoonTown persisted a non-completed result. No result was sent to MoonFind.",
      )
    }
    let callback = research_handoff_callback_url(request.handoff_url)
    let (callback_status, callback_http_status, delivery_error) = deliver_research_handoff_result(
      callback, result_package,
    )
    research_handoff_execution_reply(
      callback_status == "delivered",
      action,
      Some(request),
      execution_status,
      review_status,
      callback_status,
      callback_http_status,
      Some(result_package),
      delivery_error,
    )
  } catch {
    error =>
      research_handoff_execution_reply(
        false,
        action,
        Some(request),
        "blocked",
        "blocked",
        "not-attempted",
        0,
        None,
        "\{error}",
      )
  }
}
