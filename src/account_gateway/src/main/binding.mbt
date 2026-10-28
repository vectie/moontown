///|
/// Only concurrent reads for the identical cookie share a result. Completed
/// authorization is never cached across requests; credentials remain in memory.
struct IdentityFlight {
  gate : @async.Mutex
  mut result : @account_identity.Resolution?
}

///|
struct BrowserIdentity {
  flights : Map[String, IdentityFlight]
  resolve : async (String) -> @account_identity.Resolution
}

///|
/// Forward only platform identity cookies, never another product's workspace,
/// local preview, analytics or session credential. LunaNexa still chooses and
/// validates the cookie for its configured HTTPS/8443 audience. These names
/// cover its checked-in HTTPS and deployed HTTP-identity migration profiles.
fn identity_cookies(header : String) -> String {
  if header.length() > 16384 || header.contains("\r") || header.contains("\n") {
    return ""
  }
  let allowed = [
    "__Host-lunanexa_enterprise_oidc", "__Host-lunanexa_enterprise_oidc_8443", "lunanexa_http_enterprise_oidc",
    "lunanexa_http_enterprise_oidc_8443",
  ]
  let found : Map[String, Bool] = Map([])
  let parts : Array[String] = []
  for part in header.split(";") {
    let part = part.trim()
    guard part.find("=") is Some(separator) else { continue }
    let name = part[:separator].to_owned()
    if !allowed.contains(name) {
      continue
    }
    if found.contains(name) {
      return ""
    }
    found[name] = true
    parts.push(part.to_owned())
  }
  parts.join("; ")
}

///|
async fn BrowserIdentity::read(
  self : BrowserIdentity,
  cookie : String,
) -> @account_identity.Resolution {
  if cookie.is_empty() || cookie.length() > 16384 {
    return (self.resolve)("")
  }
  let key = @account_system.account_token_digest(cookie)
  if self.flights.get(key) is Some(flight) {
    flight.gate.acquire()
    defer flight.gate.release()
    guard flight.result is Some(result) else {
      raise @webide.BridgeError::AuthorityUnavailable
    }
    return result
  }
  let flight : IdentityFlight = { gate: Mutex(), result: None, }
  assert_true(flight.gate.try_acquire())
  self.flights[key] = flight
  defer {
    self.flights.remove(key)
    flight.gate.release()
  }
  let result = (self.resolve)(cookie)
  flight.result = Some(result)
  result
}

///|
async fn BrowserIdentity::authorize(
  self : BrowserIdentity,
  grant : @webide.Grant,
  cookie : String,
) -> Bool {
  match self.read(cookie) {
    Authenticated(session) => session.owns_subject(grant.subject_ref)
    SignedOut => false
    Disabled | Unavailable => raise @webide.BridgeError::AuthorityUnavailable
  }
}

///|
async fn reply_json(
  conn : @http.ServerConnection,
  code : Int32,
  value : Json,
) -> Unit {
  conn.send_response(code, "Account", extra_headers={
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "cross-origin-resource-policy": "same-origin",
    "vary": "Cookie",
  })
  conn.write_string(value.stringify())
  conn.end_response()
}

///|
fn legacy_account_route(path : String) -> Bool {
  path.has_prefix("/miniapp/account/") ||
  path.has_prefix("/miniapp/auth/") ||
  path == "/miniapp/marketplace/portable-packages" ||
  path.has_prefix("/miniapp/marketplace/portable-packages/")
}

///|
fn protected_account_route(path : String) -> Bool {
  path == "/account/self.json" ||
  path == "/secret-compute-room.json" ||
  path == "/miniapp/me" ||
  legacy_account_route(path)
}

///|
async fn BrowserIdentity::handle(
  self : BrowserIdentity,
  grant : @webide.Grant,
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  let path = request.path.split("?").next().unwrap_or("").to_owned()
  guard protected_account_route(path) else { return false }
  if request.meth != Get || legacy_account_route(path) {
    reply_json(conn, 403, { "error": "use_unified_account" })
    return true
  }
  // Recheck here: a principal change between authorization and projection must
  // never return the new person's resources inside the previous workspace.
  let session = match self.read(request.headers.get("cookie").unwrap_or("")) {
    Authenticated(session) if session.owns_subject(grant.subject_ref) => session
    SignedOut | Authenticated(_) => {
      reply_json(conn, 401, { "state": "sign-in-required" })
      return true
    }
    Disabled | Unavailable => {
      reply_json(conn, 503, { "state": "unavailable" })
      return true
    }
  }
  let requested_org = request.headers
    .get("x-lunanexa-organization")
    .unwrap_or("")
  if requested_org != "" && requested_org != grant.organization_id {
    reply_json(conn, 403, { "error": "reopen_workspace_for_organization" })
    return true
  }
  if path == "/secret-compute-room.json" {
    reply_json(
      conn,
      200,
      @account_compute.for_session(session, grant.organization_id),
    )
  } else {
    let account = @account_system.account_context_projection(session.context())
    reply_json(
      conn,
      200,
      if path == "/miniapp/me" {
        { "account": account }
      } else {
        {
          "state": "bound",
          "account": account,
          "workspace_id": @webide.workspace_id(grant),
        }
      },
    )
  }
  true
}
