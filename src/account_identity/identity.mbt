///| A configured federation is authoritative: failures never fall back to a

///|
/// different local principal. No password database or durable bearer copy.
pub enum Resolution {
  Disabled
  SignedOut
  Unavailable
  Authenticated(Session)
}

///|
struct Config {
  endpoint : String
  host : String
  origin : String
  prefix : String
}

///|
/// Intentionally no Debug/ToJson: session credentials stay in this package.
pub struct Session {
  priv config : Config
  priv cookie : String
  priv bearer : String
  priv account_id : String
  priv subject_ref : String
  priv issuer : String
  priv display_name : String
  priv platform_operator : Bool
}

///|
pub fn enabled() -> Bool {
  @env.get_env_var("MOONTOWN_ACCOUNT_PROVIDER").unwrap_or("") != ""
}

///|
fn endpoint_allowed(endpoint : String) -> Bool {
  if endpoint.contains("@") ||
    endpoint.contains("?") ||
    endpoint.contains("#") ||
    endpoint.contains("\\") ||
    endpoint.contains("\r") ||
    endpoint.contains("\n") {
    return false
  }
  if endpoint.has_prefix("https://") {
    return endpoint.length() > 8
  }
  for prefix in ["http://127.0.0.1:", "http://localhost:"] {
    if endpoint.has_prefix(prefix) {
      let port = endpoint[prefix.length():].trim(chars="/")
      return !port.is_empty() && port.iter().all(c => c >= '0' && c <= '9')
    }
  }
  false
}

///|
fn config() -> Config? {
  guard @env.get_env_var("MOONTOWN_ACCOUNT_PROVIDER") == Some("lunanexa") &&
    @env.get_env_var("MOONTOWN_IDENTITY_ENDPOINT") is Some(endpoint) &&
    @env.get_env_var("MOONTOWN_IDENTITY_HOST") is Some(host) &&
    endpoint_allowed(endpoint) &&
    !host.is_empty() else {
    return None
  }
  let prefix = @env.get_env_var("MOONTOWN_IDENTITY_PREFIX").unwrap_or("")
  guard prefix == "" || prefix == "/user" else { return None }
  let origin = @env.get_env_var("MOONTOWN_IDENTITY_ORIGIN").unwrap_or(
    (if endpoint.has_prefix("https://") { "https://" } else { "http://" }) +
    host,
  )
  guard origin == "https://" + host || origin == "http://" + host else {
    return None
  }
  Client::new(endpoint~, host~, origin~, prefix~).map(client => {
    client.configuration
  })
}

///|
/// Explicit deployment configuration for trusted hosts and isolated HTTP tests.
/// This client cannot accept identity claims or manufacture an authenticated
/// session; the configured authority must validate the browser cookie.
pub struct Client {
  priv configuration : Config
}

///|
pub fn Client::new(
  endpoint~ : String,
  host~ : String,
  origin~ : String,
  prefix~ : String,
) -> Client? {
  guard endpoint_allowed(endpoint) &&
    !host.is_empty() &&
    host.length() <= 253 &&
    host
    .iter()
    .all(c => {
      (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '.' ||
      c == ':'
    }) &&
    (prefix == "" || prefix == "/user") &&
    (endpoint == "https://" + host || endpoint == "http://" + host) &&
    (origin == "https://" + host || origin == "http://" + host) else {
    return None
  }
  Some({ configuration: { endpoint, host, origin, prefix, }, })
}

///|
pub async fn Client::resolve(self : Client, cookie : String) -> Resolution {
  if cookie.is_empty() || cookie.length() > 16384 {
    return SignedOut
  }
  @async.with_timeout(3500, () => resolve_inner(self.configuration, cookie)) catch {
    _ => Unavailable
  }
}

///|
/// Credential-free deployment diagnostic. Uses a fixed invalid cookie and
/// returns only the HTTP status; no account or session data is read or logged.
pub async fn Client::probe(self : Client) -> Int32 {
  @async.with_timeout(5000, () => {
    let client = identity_http_client(
      self.configuration,
      "moontown_preflight=invalid",
    )
    defer client.close()
    client.get(self.configuration.prefix + "/auth/session").code
  })
}

///|
async fn bounded_json(reader : &@io.Reader) -> Json {
  let limit = 262144
  let bytes = FixedArray::make(limit + 1, b'\x00')
  let mut length = 0
  while length <= limit {
    let count = reader.read(bytes, offset=length, max_len=limit + 1 - length)
    if count == 0 {
      return @json.parse(
        @utf8.decode(bytes.unsafe_reinterpret_as_bytes()[:length]),
      )
    }
    length += count
  }
  fail("identity response exceeded limit")
}

///|
fn parse_session(
  config : Config,
  cookie : String,
  bearer : String,
  value : Json,
) -> Session? {
  guard value
    is {
      "account_id": String(account_id),
      "subject_ref": String(subject_ref),
      "identity_issuer": String(issuer),
      "display_name": String(display_name),
      "state": String("Active"),
      ..
    } &&
    !account_id.is_empty() &&
    account_id.length() <= 128 &&
    !subject_ref.is_empty() &&
    !issuer.is_empty() &&
    !display_name.trim().is_empty() &&
    display_name.length() <= 256 else {
    return None
  }
  Some({
    config,
    cookie,
    bearer,
    account_id,
    subject_ref,
    issuer,
    display_name,
    platform_operator: match value {
      { "roles": Array(roles), .. } =>
        roles.any(role => role is String("PlatformOperator"))
      _ => false
    },
  })
}

///|
async fn resolve_inner(config : Config, cookie : String) -> Resolution {
  let client = identity_http_client(config, cookie)
  defer client.close()
  resolve_using(config, cookie, (path, bearer) => {
    // Client derives Host from the validated endpoint. Never append a second
    // Host header: that is invalid HTTP and can select a different audience.
    let response = client.get(
      config.prefix + path,
      extra_headers=if bearer.is_empty() {
        Map([])
      } else {
        { "Authorization": "Bearer " + bearer }
      },
    )
    (
      response.code,
      if response.code == 200 {
        bounded_json(client)
      } else {
        Json::null()
      },
    )
  })
}

///| Injectable transport keeps rejection/expiry and identity isolation testable

///|
/// without a real account, credentials, or a network listener.
async fn resolve_using(
  config : Config,
  cookie : String,
  read : async (String, String) -> (Int32, Json),
) -> Resolution {
  let (code, value) = read("/auth/session", "")
  if code == 401 || code == 403 {
    return SignedOut
  }
  guard code == 200 else { return Unavailable }
  guard value is { "session_token": String(bearer), .. } &&
    bearer.has_prefix("lnxs_") &&
    bearer.length() <= 4096 else {
    return Unavailable
  }
  let (code, value) = read("/v1/auth/self", bearer)
  if code == 401 || code == 403 {
    return SignedOut
  }
  guard code == 200 else { return Unavailable }
  match parse_session(config, cookie, bearer, value) {
    Some(session) => Authenticated(session)
    None => SignedOut
  }
}

///|
pub async fn resolve(cookie : String) -> Resolution {
  if !enabled() {
    return Disabled
  }
  guard config() is Some(configuration) else { return Unavailable }
  if cookie.is_empty() || cookie.length() > 16384 {
    return SignedOut
  }
  @async.with_timeout(3500, () => resolve_inner(configuration, cookie)) catch {
    _ => Unavailable
  }
}

///|
/// Identity is not a MoonTown subscription or an administrator grant.
pub fn Session::context(self : Session) -> @account_system.AccountContext {
  {
    user_id: "lunanexa:" +
    @account_system.account_token_digest(
      Json::array([self.issuer.to_json(), self.account_id.to_json()]).stringify(),
    ),
    display_name: self.display_name,
    account_kind: SignedInAccount,
    plan: VisitorPlan,
    roles: [AccountMember],
    entitlements: [ExplorePublicTown, DiscoverPublicServices, ViewOwnCompute],
    active_tenant_id: None,
    active_tenant_name: None,
    tenant_choices: [],
    home_surface: PublicTownHome,
    visitor: false,
  }
}

///| Only allowlisted, subject-authorized reads. Organization is a selection,

///|
/// never authority; LunaNexa rechecks membership on every request.
pub async fn Session::read_self(
  self : Session,
  path : String,
  organization : String,
) -> (Int32, Json) {
  guard ["/v1/machine-access/self", "/v1/portal/self/organizations"].contains(
      path,
    ) &&
    organization.length() <= 128 &&
    !organization.contains("\r") &&
    !organization.contains("\n") else {
    return (400, Json::null())
  }
  @async.with_timeout(3500, () => {
    let client = identity_http_client(self.config, self.cookie)
    defer client.close()
    let response = client.get(
      self.config.prefix + path,
      extra_headers=if organization.is_empty() {
        { "Authorization": "Bearer " + self.bearer }
      } else {
        {
          "Authorization": "Bearer " + self.bearer,
          "X-LunaNexa-Organization": organization,
        }
      },
    )
    (response.code, bounded_json(client))
  }) catch {
    _ => (503, Json::null())
  }
}

///|
pub fn Session::owns_subject(self : Session, subject : String) -> Bool {
  self.subject_ref == subject
}

///|
/// Compute visibility only. This is not a MoonTown subscription/admin grant.
pub fn Session::is_platform_operator(self : Session) -> Bool {
  self.platform_operator
}

///|
/// Exact read-only control-plane route, authenticated by the current human's
/// session. No service/operator token, arbitrary URL, or browser cookie is
/// forwarded. The controller independently checks the live PlatformOperator
/// role, including revocation. Endpoint and CA are trusted deployment settings.
pub async fn Session::read_platform_nodes(
  self : Session,
  endpoint : String,
  ca_file : String,
) -> (Int32, Json) {
  guard self.platform_operator else { return (403, Json::null()) }
  guard endpoint_allowed(endpoint) &&
    !endpoint
    .strip_prefix("https://")
    .unwrap_or(endpoint.strip_prefix("http://").unwrap_or(""))
    .contains("/") else {
    return (503, Json::null())
  }
  @async.with_timeout(3500, () => {
    let client = @http.Client(
      endpoint,
      headers={ "Authorization": "Bearer " + self.bearer },
      trust=if ca_file.is_empty() { SystemRoot } else { CustomPemFile(ca_file) },
    )
    defer client.close()
    let response = client.get("/v1/nodes")
    (
      response.code,
      if response.code == 200 {
        bounded_json(client)
      } else {
        Json::null()
      },
    )
  }) catch {
    _ => (503, Json::null())
  }
}

///|
async fn identity_http_client(config : Config, cookie : String) -> @http.Client {
  guard config.endpoint == "http://" + config.host ||
    config.endpoint == "https://" + config.host else {
    fail("Identity transport authority mismatch")
  }
  // Controller trust and public identity-edge trust can have different roots.
  @http.Client(
    config.endpoint,
    headers={
      "Cookie": cookie,
      "Origin": config.origin,
      "Sec-Fetch-Site": "same-origin",
      "Sec-Fetch-Dest": "empty",
      "Accept": "application/json",
    },
    trust=match @env.get_env_var("MOONTOWN_IDENTITY_CA_FILE") {
      Some(path) if !path.is_empty() => CustomPemFile(path)
      _ => SystemRoot
    },
  )
}
