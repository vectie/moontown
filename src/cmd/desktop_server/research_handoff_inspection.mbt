///|
struct ResearchHandoffInspectionRequest {
  contract_version : String
  handoff_url : String
  expected_contract : String
  expected_handoff_id : String
} derive(FromJson)

///|
fn research_handoff_inspection_request_version() -> String {
  "moontown.research-handoff-inspection.request.v1"
}

///|
fn research_handoff_inspection_reply_version() -> String {
  "moontown.research-handoff-inspection.reply.v1"
}

///|
fn civic_research_handoff_version() -> String {
  "moontown.civic.communication.handoff.v1"
}

///|
fn safe_loopback_research_handoff_url(url : String) -> Bool {
  if url.is_blank() ||
    url.trim().to_owned() != url ||
    !url.has_prefix("http://") ||
    url.contains("@") ||
    url.contains("#") ||
    url.contains("\\") {
    return false
  }
  let authority_and_path = url["http://".length():].to_owned()
  guard authority_and_path.find("/") is Some(separator) else { return false }
  let authority = authority_and_path[:separator].to_owned()
  let path = authority_and_path[separator:].to_owned()
  let parts = authority.split(":").to_array()
  if parts.length() != 2 ||
    !(parts[0] == "127.0.0.1" || parts[0] == "localhost") ||
    path != "/api/v1/moontown/handoff" {
    return false
  }
  let port = @string.parse_int(parts[1]) catch { _ => return false }
  port > 0 && port <= 65535 && port != 17842
}

///|
fn research_handoff_inspection_reply(
  ok : Bool,
  requested_url : String,
  upstream_status : Int,
  handoff : Json?,
  error : String,
) -> Json {
  {
    "contract_version": research_handoff_inspection_reply_version(),
    "ok": ok,
    "requested_url": requested_url,
    "upstream_status": upstream_status,
    "handoff": match handoff {
      Some(value) => value
      None => Json::null()
    },
    "error": error,
  }
}

///|
async fn inspect_research_handoff(raw : String) -> Json noraise {
  let parsed = @json.parse(raw) catch {
    _ =>
      return research_handoff_inspection_reply(
        false,
        "",
        0,
        None,
        "MoonTown received an invalid handoff-inspection request.",
      )
  }
  let request : ResearchHandoffInspectionRequest = @json.from_json(parsed) catch {
    _ =>
      return research_handoff_inspection_reply(
        false,
        "",
        0,
        None,
        "MoonTown received a request that did not match the inspection contract.",
      )
  }
  if request.contract_version != research_handoff_inspection_request_version() {
    return research_handoff_inspection_reply(
      false,
      request.handoff_url,
      0,
      None,
      "Unsupported handoff-inspection request contract.",
    )
  }
  if request.expected_contract != civic_research_handoff_version() ||
    request.expected_handoff_id.is_blank() {
    return research_handoff_inspection_reply(
      false,
      request.handoff_url,
      0,
      None,
      "The expected handoff contract or artifact id is invalid.",
    )
  }
  if !safe_loopback_research_handoff_url(request.handoff_url) {
    return research_handoff_inspection_reply(
      false,
      request.handoff_url,
      0,
      None,
      "The handoff source is denied. MoonTown only inspects the exact typed endpoint on a separate loopback service.",
    )
  }
  try {
    let (response, data) = @http.get(request.handoff_url, headers={
      "Accept": "application/json",
    })
    if response.code < 200 || response.code >= 300 {
      return research_handoff_inspection_reply(
        false,
        request.handoff_url,
        response.code,
        None,
        "The handoff source returned HTTP \{response.code}.",
      )
    }
    let text = data.text()
    if text.length() > 1024 * 1024 {
      return research_handoff_inspection_reply(
        false,
        request.handoff_url,
        response.code,
        None,
        "The handoff artifact exceeds MoonTown's 1 MiB inspection limit.",
      )
    }
    let handoff = @json.parse(text)
    guard handoff is Object(fields) else {
      return research_handoff_inspection_reply(
        false,
        request.handoff_url,
        response.code,
        None,
        "The handoff source did not return a JSON object.",
      )
    }
    if json_string_field(fields, "contract_version") !=
      request.expected_contract ||
      json_string_field(fields, "handoff_id") != request.expected_handoff_id {
      return research_handoff_inspection_reply(
        false,
        request.handoff_url,
        response.code,
        None,
        "The fetched artifact identity does not match the requested contract and handoff id.",
      )
    }
    research_handoff_inspection_reply(
      true,
      request.handoff_url,
      response.code,
      Some(handoff),
      "",
    )
  } catch {
    error =>
      research_handoff_inspection_reply(
        false,
        request.handoff_url,
        0,
        None,
        "MoonTown could not fetch the typed handoff: \{error}",
      )
  }
}
