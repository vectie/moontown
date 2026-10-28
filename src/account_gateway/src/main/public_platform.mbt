///|
/// Shared product shell with a narrow neighborhood API. No workspace
/// provisioning, Kubernetes credentials, write proxy or model dependency.
struct PublicPlatform {
  identity : BrowserIdentity
  assets : String
  controller : String
  controller_ca : String
  public_origin : String
  neighborhood_path : String?
}

///|
fn public_relative_path(path : String) -> String? {
  let path = path.split("?").next().unwrap_or("").to_owned()
  guard path.has_prefix("/moontown/") else { return None }
  let relative = path["/moontown/".length():].to_owned()
  if relative.is_empty() {
    return Some("index.html")
  }
  guard relative
    .iter()
    .all(c => {
      (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_' ||
      c == '.' ||
      c == '/'
    }) &&
    !relative.split("/").any(part => part == "" || part == "." || part == "..") else {
    return None
  }
  Some(relative)
}

///|
fn public_asset_allowed(relative : String) -> Bool {
  if relative.has_suffix(".gz") || relative.has_suffix(".etag") {
    return false
  }
  if relative == "index.html" || relative == "viewport.html" {
    return true
  }
  if relative.has_prefix("landmark-studio/") {
    return [
      ".html", ".js", ".css", ".json", ".png", ".jpg", ".webp", ".svg", ".glb", ".gltf",
      ".bin",
    ].any(ext => relative.has_suffix(ext))
  }
  if relative.has_suffix(".json") {
    return relative == "knowledge-domain-catalog.json" ||
      relative == "tilemap/modules/wenyu-town-modules.json" ||
      (
        relative.has_prefix("tilemap/") &&
        !relative.has_prefix("tilemap/modules/")
      )
  }
  [
    ".js", ".mjs", ".css", ".png", ".webp", ".svg", ".jpg", ".jpeg", ".woff2", ".wasm",
  ].any(ext => relative.has_suffix(ext))
}

///|
fn public_content_type(path : String) -> String {
  for
    (suffix, kind) in [
      (".html", "text/html; charset=utf-8"),
      (".js", "text/javascript; charset=utf-8"),
      (".mjs", "text/javascript; charset=utf-8"),
      (".css", "text/css; charset=utf-8"),
      (".json", "application/json"),
      (".svg", "image/svg+xml"),
      (".png", "image/png"),
      (".webp", "image/webp"),
      (".jpg", "image/jpeg"),
      (".jpeg", "image/jpeg"),
      (".woff2", "font/woff2"),
      (".wasm", "application/wasm"),
    ] {
    if path.has_suffix(suffix) {
      return kind
    }
  }
  "application/octet-stream"
}

///|
async fn PublicPlatform::asset(
  self : PublicPlatform,
  request : @http.Request,
  conn : @http.ServerConnection,
  relative : String,
) -> Bool {
  guard public_asset_allowed(relative) else { return false }
  // Resolve beneath a separate, immutable public asset volume, never /workspace.
  let path = @fs.realpath(self.assets + "/" + relative) catch {
    _ => return false
  }
  guard path.has_prefix(self.assets + "/") && @fs.kind(path) is Regular else {
    return false
  }
  let gzip = request.headers
    .get("accept-encoding")
    .unwrap_or("")
    .split(",")
    .any(item => item.trim() == "gzip") &&
    @fs.exists(path + ".gz")
  let selected = if gzip { @fs.realpath(path + ".gz") } else { path }
  guard selected.has_prefix(self.assets + "/") && @fs.kind(selected) is Regular else {
    return false
  }
  let headers : @http.Headers = {
    "content-type": public_content_type(relative),
    "cache-control": "public, no-cache",
    "vary": "Accept-Encoding",
    "x-content-type-options": "nosniff",
    "referrer-policy": "same-origin",
  }
  if gzip {
    headers["content-encoding"] = "gzip"
  }
  let tag_path = path + ".etag"
  if @fs.exists(tag_path) &&
    @fs.realpath(tag_path).has_prefix(self.assets + "/") {
    let digest = @fs.read_file(tag_path).text().trim().to_owned()
    let tag = if gzip {
      "\"gzip-" + digest.trim(chars="\"").to_owned() + "\""
    } else {
      digest
    }
    headers["etag"] = tag
    if request.headers.get("if-none-match") == Some(tag) {
      conn.send_response(304, "Not Modified", extra_headers=headers)
      conn.end_response()
      return true
    }
  }
  let file = @fs.open(selected, mode=ReadOnly)
  defer file.close()
  headers["content-length"] = file.size().to_string()
  conn.send_response(200, "OK", extra_headers=headers)
  conn.write_reader(file)
  conn.end_response()
  true
}

///|
fn platform_storage_scope(session : @account_identity.Session?) -> String {
  match session {
    Some(session) =>
      "account-" +
      @account_system.account_token_digest(session.context().user_id)
    None => "public"
  }
}

///|
async fn PublicPlatform::handle(
  self : PublicPlatform,
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  if public_relative_path(request.path) is Some(relative) &&
    neighborhood_route(relative) {
    self.neighborhood(request, body, conn, relative)
    return
  }
  guard request.meth == Get else {
    return reply_json(conn, 405, { "error": "read_only_town" })
  }
  if request.path == "/health" {
    return reply_json(conn, 200, { "status": "ok", "mode": "public" })
  }
  if request.path == "/moontown" {
    conn.send_response(308, "Permanent Redirect", extra_headers={
      "location": "/moontown/",
      "cache-control": "no-store",
    })
    conn.end_response()
    return
  }
  if request.path == "/moontown/connect" {
    // The portal's single-use handoff lives in the URL fragment. An HTTP
    // redirect preserves that fragment without exposing it to this service.
    conn.send_response(307, "Temporary Redirect", extra_headers={
      "location": "/moontown/workspace/connect",
      "cache-control": "no-store",
      "referrer-policy": "no-referrer",
    })
    conn.end_response()
    return
  }
  guard public_relative_path(request.path) is Some(relative) else {
    return reply_json(conn, 404, { "error": "not_found" })
  }
  if [
      "platform-scope.js", "account/self.json", "miniapp/me", "secret-compute-room.json",
    ].contains(relative) {
    if request.headers.get("sec-fetch-site") == Some("cross-site") {
      return reply_json(conn, 403, { "error": "same_origin_required" })
    }
    let session = match
      self.identity.read(request.headers.get("cookie").unwrap_or("")) {
      Authenticated(session) => Some(session)
      SignedOut => None
      Disabled | Unavailable =>
        return reply_json(conn, 503, { "state": "unavailable" })
    }
    let scope = platform_storage_scope(session)
    if relative == "platform-scope.js" {
      conn.send_response(200, "OK", extra_headers={
        "content-type": "text/javascript; charset=utf-8",
        "cache-control": "no-store",
        "vary": "Cookie",
        "x-content-type-options": "nosniff",
        "cross-origin-resource-policy": "same-origin",
      })
      conn.write_string(
        "globalThis.__MOONTOWN_PUBLIC_PLATFORM=true;globalThis.__MOONTOWN_ACCOUNT_SCOPE=" +
        scope.to_json().stringify() +
        ";",
      )
      conn.end_response()
      return
    }
    if relative == "secret-compute-room.json" {
      let value = match session {
        None => @account_compute.public_demo()
        Some(session) =>
          if session.is_platform_operator() {
            @account_compute.platform_for_session(
              session,
              self.controller,
              self.controller_ca,
            )
          } else {
            @account_compute.for_session(
              session,
              request.headers.get("x-lunanexa-organization").unwrap_or(""),
            )
          }
      }
      return reply_json(conn, 200, value)
    }
    let account = session
      .map(s => @account_system.account_context_projection(s.context()))
      .unwrap_or(Json::null())
    reply_json(conn, 200, {
      "state": if session is Some(_) {
        "bound"
      } else {
        "sign-in-required"
      },
      "account": account,
      "storage_scope": scope,
    })
    return
  }
  if self.asset(request, conn, relative) {
    return
  }
  // All operational snapshots and mutation trees stay absent. The product's
  // built-in scene provides demo agents without copying a tenant's runtime.
  reply_json(conn, 404, { "error": "not_found" })
}

///|
async fn run_public_platform(identity : BrowserIdentity) -> Unit {
  let platform : PublicPlatform = {
    identity,
    assets: @fs.realpath(required("MOONTOWN_PUBLIC_ASSETS")),
    controller: required("MOONTOWN_COMPUTE_CONTROLLER_ENDPOINT"),
    controller_ca: required("MOONTOWN_COMPUTE_CONTROLLER_CA_FILE"),
    public_origin: required("LUNANEXA_WEBIDE_PUBLIC_ORIGIN"),
    neighborhood_path: @env.get_env_var("MOONTOWN_NEIGHBORHOOD_STATE_FILE").filter(path => {
        path.has_prefix("/") && !path.trim().is_empty()
      },
    ),
  }
  let server = @http.Server(
    @socket.Addr::parse(required("LUNANEXA_WEBIDE_BIND")),
  )
  defer server.close()
  server.run_forever(
    (request, body, conn) => platform.handle(request, body, conn),
    max_connections=256,
    allow_failure=true,
  )
}
