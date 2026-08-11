///|
fn env_value(name : String) -> String? {
  match @env.get_env_var(name) {
    Some(value) if !value.trim().is_empty() => Some(value.trim().to_owned())
    _ => None
  }
}

///|
fn miniapp_bind() -> String {
  env_value("MOONTOWN_MINIAPP_BIND").unwrap_or("127.0.0.1:18191")
}

///|
fn session_token() -> String {
  env_value("MOONTOWN_MINIAPP_SESSION_TOKEN").unwrap_or("")
}

///|
let visitor_session_rng : @random.Rand = @random.Rand::chacha8()

///|
fn parse_configured_account_plan(
  value : String,
) -> @account_system.AccountPlan raise {
  match value.trim().to_lower() {
    "visitor" => @account_system.VisitorPlan
    "paid" => @account_system.PaidPlan
    "enterprise" => @account_system.EnterprisePlan
    _ => fail("MOONTOWN_ACCOUNT_PLAN must be visitor, paid, or enterprise")
  }
}

///|
fn configured_account_plan() -> @account_system.AccountPlan raise {
  parse_configured_account_plan(
    env_value("MOONTOWN_ACCOUNT_PLAN").unwrap_or("visitor"),
  )
}

///|
fn configured_personal_plan() -> @account_system.AccountPlan raise {
  personal_plan_for_account_plan(configured_account_plan())
}

///|
fn personal_plan_for_account_plan(
  configured : @account_system.AccountPlan,
) -> @account_system.AccountPlan {
  match configured {
    @account_system.EnterprisePlan => @account_system.PaidPlan
    plan => plan
  }
}

///|
fn configured_platform_roles() -> Array[@account_system.AccountRole] raise {
  let roles : Array[@account_system.AccountRole] = []
  for
    raw in env_value("MOONTOWN_ACCOUNT_PLATFORM_ROLES").unwrap_or("").split(",") {
    match raw.trim().to_lower() {
      "platform-admin" => roles.push(@account_system.PlatformAdmin)
      "publisher" => roles.push(@account_system.AccountPublisher)
      "editor" => roles.push(@account_system.AccountEditor)
      "member" => roles.push(@account_system.AccountMember)
      "" | "none" => ()
      value =>
        fail("unsupported MOONTOWN_ACCOUNT_PLATFORM_ROLES value: \{value}")
    }
  }
  roles
}

///|
fn configured_tenant_access() -> Array[@account_system.AccountTenantAccess] raise {
  if configured_account_plan() != @account_system.EnterprisePlan {
    return []
  }
  [
    {
      tenant_id: env_value("MOONTOWN_MINIAPP_TENANT_ID")
      .unwrap_or("local-town")
      .to_lower(),
      tenant_name: env_value("MOONTOWN_MINIAPP_TENANT_NAME").unwrap_or(
        "Local town",
      ),
      plan: @account_system.EnterprisePlan,
      roles: [
        @account_system.AccountMember,
        @account_system.AccountEditor,
        @account_system.AccountPublisher,
        @account_system.OrganizationAdmin,
      ],
      active: true,
      version: 1,
    },
  ]
}

///|
fn account_application() -> @account_system.AccountApplication raise {
  let user_id = env_value("MOONTOWN_MINIAPP_PRINCIPAL_ID")
    .unwrap_or("local-operator")
    .to_lower()
  @account_system.account_application(
    @storage.moontown_product_state_dir() + "/accounts/state.json",
    {
      user_id,
      display_name: env_value("MOONTOWN_MINIAPP_PRINCIPAL_NAME").unwrap_or(
        "Local operator",
      ),
      // Enterprise is tenant-scoped; outside an active tenant this principal
      // retains only its paid personal workspace.
      personal_plan: configured_personal_plan(),
      platform_roles: configured_platform_roles(),
      tenant_access: configured_tenant_access(),
      active: true,
      version: 1,
    },
    "bootstrap:\{user_id}",
    marketplace_bootstrap_opaque_session(),
  )
}

///|
fn generated_session_identity(
  session_kind : String,
  now_ms : UInt64,
) -> (String, String) {
  let nonce = visitor_session_rng.uint64().to_string(radix=16)
  let session_id = "\{session_kind}-\{now_ms}-\{nonce}"
  (session_id, "session:\{session_id}:\{visitor_session_rng.uint64()}")
}

///|
fn visitor_session_identity(now_ms : UInt64) -> (String, String) {
  generated_session_identity("visitor", now_ms)
}

///|
fn operator_policy_path() -> String {
  env_value("MOONTOWN_OPERATOR_POLICY_PATH").unwrap_or(
    "assets/templates/operator-request-policy.json",
  )
}

///|
fn loopback_bind(bind : String) -> Bool {
  bind.has_prefix("127.0.0.1:") ||
  bind.has_prefix("localhost:") ||
  bind.has_prefix("[::1]:")
}

///|
fn privileged_bootstrap_configured(
  plan : @account_system.AccountPlan,
  roles : Array[@account_system.AccountRole],
) -> Bool {
  plan != @account_system.VisitorPlan || !roles.is_empty()
}

///|
fn request_path(request : @http.Request) -> String {
  match request.path.find("?") {
    Some(index) => request.path[:index].to_owned()
    None => request.path
  }
}

///|
fn request_header(request : @http.Request, name : String) -> String {
  request.headers.get(name).unwrap_or("").trim().to_owned()
}

///|
fn http_method_is_get(request_method : @http.RequestMethod) -> Bool {
  request_method is @http.Get
}

///|
fn http_method_is_post(request_method : @http.RequestMethod) -> Bool {
  request_method is @http.Post
}

///|
async fn send_text(
  conn : @http.ServerConnection,
  code : Int,
  body : String,
) -> Unit {
  let encoded = @utf8.encode(body)
  conn.send_response(code, if code < 400 { "OK" } else { "Error" }, extra_headers={
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": encoded.length().to_string(),
    "Cache-Control": "no-store",
  })
  conn.write(encoded)
  conn.end_response()
}

///|
async fn send_json(
  conn : @http.ServerConnection,
  code : Int,
  value : Json,
) -> Unit {
  send_text(conn, code, value.stringify(indent=2))
}

///|
async fn require_account_context(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> @account_system.AccountContext? {
  let supplied = request_header(request, "x-miniapp-session")
  match account_application().resolve(supplied, now_ms=@env.now()) {
    Some(context) => Some(context)
    None => {
      send_json(conn, 401, {
        "ok": false,
        "error": "missing_expired_or_invalid_account_session",
      })
      None
    }
  }
}

///|
async fn require_account_entitlement(
  context : @account_system.AccountContext,
  entitlement : @account_system.AccountEntitlement,
  conn : @http.ServerConnection,
) -> Bool {
  if context.has_entitlement(entitlement) {
    return true
  }
  send_json(conn, 403, {
    "ok": false,
    "error": "account_entitlement_required",
    "required": @account_system.account_entitlement_name(entitlement),
    "plan": @account_system.account_plan_name(context.plan),
  })
  false
}

///|
async fn require_json_write(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  if !http_method_is_post(request.meth) {
    send_json(conn, 405, { "ok": false, "error": "POST required" })
    return false
  }
  require_bounded_json_body(request, conn)
}

///|
async fn require_json_put(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  if !(request.meth is @http.Put) {
    send_json(conn, 405, { "ok": false, "error": "PUT required" })
    return false
  }
  require_bounded_json_body(request, conn)
}

///|
async fn require_bounded_json_body(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  let content_type = request_header(request, "content-type").to_lower()
  if !content_type.has_prefix("application/json") {
    send_json(conn, 415, { "ok": false, "error": "application/json required" })
    return false
  }
  let content_length = request_header(request, "content-length")
  let transfer_encoding = request_header(request, "transfer-encoding")
  if !transfer_encoding.is_empty() || content_length.is_empty() {
    send_json(conn, 411, {
      "ok": false,
      "error": "bounded content-length required",
    })
    return false
  }
  let size = @string.parse_int(content_length) catch {
    _ => {
      send_json(conn, 400, { "ok": false, "error": "invalid content-length" })
      return false
    }
  }
  if size < 0 || size > 128 * 1024 {
    send_json(conn, 413, { "ok": false, "error": "request body too large" })
    return false
  }
  true
}

///|
fn tenant_switch_target(body : String) -> String? raise {
  guard @json.parse(body) is Object(fields) else {
    fail("tenant switch body must be a JSON object")
  }
  match fields.get("tenant_id") {
    Some(String(value)) if !value.trim().is_empty() =>
      Some(value.trim().to_owned().to_lower())
    Some(Null) | None => None
    _ => fail("tenant_id must be a string or null")
  }
}

///|
fn account_management_fields(body : String) -> Map[String, Json] raise {
  guard @json.parse(body) is Object(fields) else {
    fail("account management body must be a JSON object")
  }
  fields
}

///|
fn account_management_string(
  fields : Map[String, Json],
  key : String,
) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn account_management_bool(
  fields : Map[String, Json],
  key : String,
) -> Bool raise {
  match fields.get(key) {
    Some(True) => true
    Some(False) => false
    _ => fail("\{key} must be a boolean")
  }
}

///|
fn miniapp_transport_id(request : @http.Request) -> String {
  let supplied = request_header(request, "x-moondesk-transport-id")
  if supplied.is_empty() {
    "moondesk-miniapp-adapter"
  } else {
    supplied
  }
}

///| The bootstrap session is fixed by server configuration and never derived

///|
/// from request input.
fn marketplace_bootstrap_opaque_session() -> String {
  let configured = session_token()
  if configured.is_empty() {
    "moontown-local-development-session"
  } else {
    configured
  }
}

///|
fn select_marketplace_opaque_session(
  supplied : String,
  _bootstrap : String,
) -> String {
  supplied
}

///| Marketplace identity comes only from an opaque pre-provisioned session.

///|
/// The legacy x-miniapp-user-id header is intentionally not consulted.
fn marketplace_opaque_session(request : @http.Request) -> String {
  select_marketplace_opaque_session(
    request_header(request, "x-miniapp-session"),
    marketplace_bootstrap_opaque_session(),
  )
}

///|
fn marketplace_principal_for_account(
  context : @account_system.AccountContext,
) -> @town_marketplace.MarketplacePrincipal {
  let roles : Array[String] = []
  if context.has_entitlement(@account_system.PublishTownContent) {
    roles.push("publisher")
  }
  if context.has_entitlement(@account_system.ModerateTownContent) {
    roles.push("moderator")
  }
  if context.has_entitlement(@account_system.ManageOrganizationBilling) ||
    context.has_entitlement(@account_system.ManagePlatformTenants) {
    roles.push("advertiser")
  }
  {
    principal_id: context.user_id,
    tenant_id: context.active_tenant_id.unwrap_or("personal:\{context.user_id}"),
    display_name: context.display_name,
    workspace_ids: [],
    roles,
    interest_tags: [],
    active: true,
    version: 1,
  }
}

///|
fn marketplace_application() -> @town_marketplace.MarketplaceApplication raise {
  let principal_id = env_value("MOONTOWN_MINIAPP_PRINCIPAL_ID")
    .unwrap_or("local-operator")
    .to_lower()
  let tenant_id = env_value("MOONTOWN_MINIAPP_TENANT_ID")
    .unwrap_or("local-town")
    .to_lower()
  @town_marketplace.marketplace_application(
    @storage.moontown_product_state_dir() + "/marketplace/state.json",
    {
      principal_id,
      tenant_id,
      display_name: env_value("MOONTOWN_MINIAPP_PRINCIPAL_NAME").unwrap_or(
        "Local operator",
      ),
      workspace_ids: [],
      roles: ["publisher", "advertiser"],
      interest_tags: [],
      active: true,
      version: 1,
    },
    "bootstrap:\{principal_id}",
    marketplace_bootstrap_opaque_session(),
  )
}

///|
fn query_hex_nibble(value : Byte) -> Int? {
  if value >= b'0' && value <= b'9' {
    Some(value.to_int() - b'0'.to_int())
  } else if value >= b'a' && value <= b'f' {
    Some(value.to_int() - b'a'.to_int() + 10)
  } else if value >= b'A' && value <= b'F' {
    Some(value.to_int() - b'A'.to_int() + 10)
  } else {
    None
  }
}

///| Decode one application/x-www-form-urlencoded query component, including

///| UTF-8 percent sequences. Malformed escapes remain literal instead of being

///|
/// silently dropped or reinterpreted.
fn decode_query_component(value : String) -> String {
  let input = @utf8.encode(value.replace(old="+", new=" "))
  let output : Array[Byte] = []
  let mut index = 0
  while index < input.length() {
    if input[index] == b'%' && index + 2 < input.length() {
      match
        (query_hex_nibble(input[index + 1]), query_hex_nibble(input[index + 2])) {
        (Some(high), Some(low)) => {
          output.push((high * 16 + low).to_byte())
          index += 3
        }
        _ => {
          output.push(input[index])
          index += 1
        }
      }
    } else {
      output.push(input[index])
      index += 1
    }
  }
  @utf8.decode_lossy(Bytes::from_array(output))
}

///|
fn request_query_parameter(raw_path : String, name : String) -> String {
  guard raw_path.find("?") is Some(index) else { return "" }
  for pair in raw_path[index + 1:].split("&") {
    let pieces = pair.split("=").to_array()
    if pieces.length() >= 1 && pieces[0] == name {
      return if pieces.length() == 1 {
        ""
      } else {
        decode_query_component(pieces[1:].join("="))
      }
    }
  }
  ""
}

///|
fn marketplace_operation(
  path : String,
  is_get : Bool,
  is_post : Bool,
) -> String? {
  if path == @town_contract.miniapp_marketplace_search_path() && is_get {
    Some("search")
  } else if path == @town_contract.miniapp_marketplace_recommendations_path() &&
    is_get {
    Some("recommendations")
  } else if path == @town_contract.miniapp_marketplace_feed_path() && is_get {
    Some("feed")
  } else if path == @town_contract.miniapp_marketplace_public_index_path() &&
    is_get {
    Some("public-index")
  } else if path == @town_contract.miniapp_marketplace_review_queue_path() &&
    is_get {
    Some("review-queue")
  } else if path == @town_contract.miniapp_marketplace_agent_listing_path() &&
    is_post {
    Some("upsert-agent")
  } else if path == @town_contract.miniapp_marketplace_building_listing_path() &&
    is_post {
    Some("upsert-building")
  } else if path == @town_contract.miniapp_marketplace_listing_transition_path() &&
    is_post {
    Some("transition-listing")
  } else if path == @town_contract.miniapp_marketplace_listing_action_path() &&
    is_post {
    Some("listing-action")
  } else if path == @town_contract.miniapp_marketplace_action_requests_path() &&
    is_get {
    Some("action-requests")
  } else if path == @town_contract.miniapp_marketplace_action_decision_path() &&
    is_post {
    Some("decide-action-request")
  } else if path == @town_contract.miniapp_marketplace_action_retry_path() &&
    is_post {
    Some("prepare-action-handoff")
  } else if path == @town_contract.miniapp_marketplace_channels_path() {
    if is_get {
      Some("list-channels")
    } else if is_post {
      Some("create-channel")
    } else {
      None
    }
  } else if path == @town_contract.miniapp_marketplace_messages_path() {
    if is_get {
      Some("list-messages")
    } else if is_post {
      Some("send-message")
    } else {
      None
    }
  } else if path == @town_contract.miniapp_marketplace_notifications_path() &&
    is_get {
    Some("notifications")
  } else if path == @town_contract.miniapp_marketplace_shared_listings_path() &&
    is_get {
    Some("shared-listings")
  } else if path == @town_contract.miniapp_marketplace_notifications_read_path() &&
    is_post {
    Some("read-notification")
  } else if path == @town_contract.miniapp_marketplace_subscriptions_path() &&
    is_post {
    Some("subscribe")
  } else if path == @town_contract.miniapp_marketplace_share_grants_path() &&
    is_post {
    Some("share-grant")
  } else if path ==
    @town_contract.miniapp_marketplace_share_grants_revoke_path() &&
    is_post {
    Some("revoke-share-grant")
  } else if path == @town_contract.miniapp_marketplace_share_preview_path() &&
    is_post {
    Some("share-preview")
  } else if path == @town_contract.miniapp_marketplace_sponsored_path() &&
    is_post {
    Some("sponsor")
  } else {
    None
  }
}

///|
async fn handle_marketplace_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  path : String,
  account_context : @account_system.AccountContext,
) -> Bool {
  guard marketplace_operation(
      path,
      http_method_is_get(request.meth),
      http_method_is_post(request.meth),
    )
    is Some(operation) else {
    return false
  }
  let writes = http_method_is_post(request.meth)
  if !require_account_entitlement(
      account_context,
      @account_system.UseMarketplaceActions,
      conn,
    ) {
    return true
  }
  if writes {
    if !require_json_write(request, conn) {
      return true
    }
  }
  let query = if operation == "list-messages" {
    request_query_parameter(request.path, "channel_id")
  } else {
    request_query_parameter(request.path, "q")
  }
  let payload = if writes { body.read_all().text() } else { "" }
  let opaque_session = marketplace_opaque_session(request)
  let marketplace = marketplace_application()
  let marketplace_now_ms = @env.now()
  marketplace.synchronize_account_session(
    marketplace_principal_for_account(account_context),
    opaque_session,
    now_ms=marketplace_now_ms,
    expires_at_ms=marketplace_now_ms + 300000UL,
  ) catch {
    error => {
      println("marketplace account synchronization denied: \{error}")
      send_json(conn, 403, {
        "ok": false,
        "error": "marketplace_account_synchronization_denied",
      })
      return true
    }
  }
  let initial_result = marketplace.execute(
    opaque_session,
    operation,
    payload,
    query,
    now_ms=@env.now(),
  ) catch {
    error => {
      println(
        "marketplace request denied: operation=\{operation} reason=\{error}",
      )
      send_json(conn, 403, {
        "ok": false,
        "error": "marketplace_request_denied",
        "operation": operation,
        "message": "The request failed marketplace policy or authorization checks.",
      })
      return true
    }
  }
  let result = if operation == "decide-action-request" ||
    operation == "prepare-action-handoff" {
    complete_marketplace_action_operation(
      operation,
      opaque_session,
      payload,
      initial_result,
      now_ms=@env.now(),
    ) catch {
      _ => {
        send_json(
          conn,
          202,
          marketplace_pending_handoff_result(operation, initial_result),
        )
        return true
      }
    }
  } else {
    initial_result
  }
  send_json(conn, if writes { 202 } else { 200 }, result)
  true
}

///|
fn handoff_kind(body : String) -> String {
  let parsed = @json.parse(body) catch { _ => Json::null() }
  match parsed {
    Object(fields) =>
      match fields.get("kind") {
        Some(String(value)) => value.trim().to_owned().to_lower()
        _ => ""
      }
    _ => ""
  }
}

///|
fn review_decision_route(path : String) -> Bool {
  path == @town_contract.miniapp_review_decision_path() ||
  (path.has_prefix("/miniapp/reviews/") && path.has_suffix("/decision"))
}

///|
fn catalog_string(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn canonical_catalog_book_id(value : String) -> Bool {
  if value.is_empty() || value.has_prefix("-") || value.has_suffix("-") {
    return false
  }
  for char in value {
    if !((char >= 'a' && char <= 'z') ||
      (char >= '0' && char <= '9') ||
      char == '-') {
      return false
    }
  }
  true
}

///| The phone receives only symbolic catalog identity and display metadata.

///|
/// The trusted workspace root never crosses the MoonTown boundary.
async fn miniapp_installed_book_catalog() -> Array[Json] {
  let result : Array[Json] = []
  let allowed_root = @fs.realpath(
    @storage.moontown_active_workspace_root() + "/books",
  ) catch {
    _ => return result
  }
  for
    entry in @moonbook.load_or_create_catalog(
      path=@moonbook.default_catalog_path(),
    ) {
    guard entry.to_json() is Object(fields) else { continue }
    let id = catalog_string(fields, "id")
    let declared_root = catalog_string(fields, "workspace_root")
    let workspace_root = @fs.realpath(declared_root) catch { _ => continue }
    if canonical_catalog_book_id(id) &&
      workspace_root == allowed_root + "/" + id &&
      (
        @fs.exists(workspace_root + "/book.json") ||
        @fs.exists(workspace_root + "/book/book.json") ||
        @fs.exists(workspace_root + "/book/moonbook-ui-state.json")
      ) {
      result.push({
        "id": id,
        "name": catalog_string(fields, "name"),
        "purpose": catalog_string(fields, "purpose"),
      })
    }
  }
  result
}

///|
fn catalog_contains_book(catalog : Array[Json], book_id : String) -> Bool {
  catalog.any(entry => {
    match entry {
      Object(fields) => catalog_string(fields, "id") == book_id
      _ => false
    }
  })
}

///| The miniapp chooses one installed book. MoonTown derives the symbolic

///| workspace/building binding from that catalog identity rather than trusting

///|
/// client-supplied location metadata.
fn bind_miniapp_supervisor_draft(
  draft : @supervisor_setup.SupervisorProfileDraft,
  catalog : Array[Json],
) -> @supervisor_setup.SupervisorProfileDraft raise {
  if draft.book_ids.length() != 1 ||
    !catalog_contains_book(catalog, draft.book_ids[0]) ||
    draft.max_active_workers != 3 {
    fail("supervisor binding must select one currently installed MoonBook")
  }
  let book_id = draft.book_ids[0]
  { ..draft, workspace_id: book_id, building_id: book_id }
}

///|
fn profile_binding_is_installed(snapshot : Json, catalog : Array[Json]) -> Bool {
  guard snapshot is Object(root) &&
    root.get("profile") is Some(Object(profile)) &&
    profile.get("bindings") is Some(Object(bindings)) &&
    bindings.get("bookIds") is Some(Array(book_ids)) &&
    book_ids.length() == 1 &&
    book_ids[0] is String(book_id) else {
    return false
  }
  catalog_contains_book(catalog, book_id)
}

///|
async fn handle_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let path = request_path(request)
  if request.meth is @http.Get && path == @town_contract.miniapp_health_path() {
    send_json(conn, 200, {
      "ok": true,
      "service": "moontown-miniapp",
      "schema": @town_contract.schema_version(),
    })
    return
  }
  if request.meth is @http.Get && path == @town_contract.miniapp_contract_path() {
    send_json(conn, 200, @town_contract.miniapp_contract())
    return
  }
  if path == @town_contract.miniapp_visitor_session_path() {
    if !require_json_write(request, conn) {
      return
    }
    let now_ms = @env.now()
    let (visitor_id, opaque_token) = visitor_session_identity(now_ms)
    let result = account_application().create_visitor_session(
      opaque_token,
      visitor_id,
      now_ms~,
    ) catch {
      error => {
        send_json(conn, 409, {
          "ok": false,
          "error": "visitor_session_failed",
          "message": "\{error}",
        })
        return
      }
    }
    send_json(conn, 201, {
      "ok": true,
      "session_token": result.opaque_token,
      "expires_in_ms": 86400000,
      "account": @account_system.account_context_projection(result.context),
    })
    return
  }
  guard require_account_context(request, conn) is Some(account_context) else {
    return
  }
  let marketplace_handled = handle_marketplace_request(
    request, body, conn, path, account_context,
  )
  if marketplace_handled {
    return
  }
  if path == @town_contract.miniapp_account_logout_path() {
    if !require_json_write(request, conn) {
      return
    }
    account_application().logout(
      request_header(request, "x-miniapp-session"),
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 409, {
          "ok": false,
          "error": "account_logout_failed",
          "message": "\{error}",
        })
        return
      }
    }
    send_json(conn, 200, { "ok": true, "session_revoked": true })
    return
  }
  if path == @town_contract.miniapp_account_context_path() {
    if !(request.meth is @http.Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    send_json(conn, 200, {
      "ok": true,
      "account": @account_system.account_context_projection(account_context),
    })
    return
  }
  if path == @town_contract.miniapp_account_billing_path() {
    let token = request_header(request, "x-miniapp-session")
    if request.meth is @http.Get {
      let snapshot = account_application().billing_snapshot(
        token,
        now_ms=@env.now(),
      ) catch {
        error => {
          send_json(conn, 403, {
            "ok": false,
            "error": "account_billing_denied",
            "message": "\{error}",
          })
          return
        }
      }
      send_json(conn, 200, { "ok": true, "billing": snapshot })
      return
    }
    if !require_json_write(request, conn) {
      return
    }
    let fields = account_management_fields(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, {
          "ok": false,
          "error": "invalid_account_billing_request",
          "message": "\{error}",
        })
        return
      }
    }
    let operation = account_management_string(fields, "action")
    let active = match operation {
      "activate" => true
      "cancel" => false
      _ => {
        send_json(conn, 400, {
          "ok": false,
          "error": "billing action must be activate or cancel",
        })
        return
      }
    }
    let updated = account_application().set_paid_subscription(
      token,
      active,
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 403, {
          "ok": false,
          "error": "account_billing_denied",
          "message": "\{error}",
        })
        return
      }
    }
    send_json(conn, 200, {
      "ok": true,
      "account": @account_system.account_context_projection(updated),
    })
    return
  }
  if path == @town_contract.miniapp_account_tenant_switch_path() {
    if !require_json_write(request, conn) {
      return
    }
    let switched = account_application().switch_tenant(
      request_header(request, "x-miniapp-session"),
      tenant_switch_target(body.read_all().text()),
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 403, {
          "ok": false,
          "error": "tenant_switch_denied",
          "message": "\{error}",
        })
        return
      }
    }
    send_json(conn, 200, {
      "ok": true,
      "account": @account_system.account_context_projection(switched),
    })
    return
  }
  if path == @town_contract.miniapp_enterprise_management_path() {
    let token = request_header(request, "x-miniapp-session")
    if request.meth is @http.Get {
      let snapshot = account_application().enterprise_snapshot(
        token,
        now_ms=@env.now(),
      ) catch {
        error => {
          send_json(conn, 403, {
            "ok": false,
            "error": "enterprise_management_denied",
            "message": "\{error}",
          })
          return
        }
      }
      send_json(conn, 200, { "ok": true, "enterprise": snapshot })
      return
    }
    if !require_json_write(request, conn) {
      return
    }
    let fields = account_management_fields(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, {
          "ok": false,
          "error": "invalid_enterprise_management_request",
          "message": "\{error}",
        })
        return
      }
    }
    let operation = account_management_string(fields, "action")
    let user_id = account_management_string(fields, "user_id").to_lower()
    if operation == "remove-member" {
      let updated = account_application().enterprise_remove_member(
        token,
        user_id,
        now_ms=@env.now(),
      ) catch {
        error => {
          send_json(conn, 403, {
            "ok": false,
            "error": "enterprise_member_removal_denied",
            "message": "\{error}",
          })
          return
        }
      }
      send_json(conn, 200, { "ok": true, "member": updated })
      return
    }
    if operation != "upsert-member" {
      send_json(conn, 400, {
        "ok": false,
        "error": "enterprise action must be upsert-member or remove-member",
      })
      return
    }
    let organization_admin = account_management_bool(
      fields, "organization_admin",
    ) catch {
      error => {
        send_json(conn, 400, {
          "ok": false,
          "error": "invalid_enterprise_member_role",
          "message": "\{error}",
        })
        return
      }
    }
    let now_ms = @env.now()
    let (generated_session_id, generated_token) = generated_session_identity(
      "enterprise", now_ms,
    )
    let result = account_application().enterprise_upsert_member(
      token,
      user_id,
      account_management_string(fields, "display_name"),
      organization_admin,
      generated_session_id,
      generated_token,
      now_ms~,
    ) catch {
      error => {
        send_json(conn, 403, {
          "ok": false,
          "error": "enterprise_member_upsert_denied",
          "message": "\{error}",
        })
        return
      }
    }
    send_json(conn, 201, {
      "ok": true,
      "session_token": result.opaque_token,
      "account": @account_system.account_context_projection(result.context),
    })
    return
  }
  if path == @town_contract.miniapp_admin_management_path() {
    let token = request_header(request, "x-miniapp-session")
    if request.meth is @http.Get {
      let snapshot = account_application().admin_snapshot(
        token,
        now_ms=@env.now(),
      ) catch {
        error => {
          send_json(conn, 403, {
            "ok": false,
            "error": "admin_management_denied",
            "message": "\{error}",
          })
          return
        }
      }
      send_json(conn, 200, { "ok": true, "admin": snapshot })
      return
    }
    if !require_json_write(request, conn) {
      return
    }
    let fields = account_management_fields(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, {
          "ok": false,
          "error": "invalid_admin_management_request",
          "message": "\{error}",
        })
        return
      }
    }
    let operation = account_management_string(fields, "action")
    let user_id = account_management_string(fields, "user_id").to_lower()
    if operation == "set-active" {
      let active = account_management_bool(fields, "active") catch {
        error => {
          send_json(conn, 400, {
            "ok": false,
            "error": "invalid_account_active_state",
            "message": "\{error}",
          })
          return
        }
      }
      let updated = account_application().admin_set_account_active(
        token,
        user_id,
        active,
        now_ms=@env.now(),
      ) catch {
        error => {
          send_json(conn, 403, {
            "ok": false,
            "error": "admin_account_lifecycle_denied",
            "message": "\{error}",
          })
          return
        }
      }
      send_json(conn, 200, { "ok": true, "account": updated })
      return
    }
    if operation != "create-account" {
      send_json(conn, 400, {
        "ok": false,
        "error": "admin action must be create-account or set-active",
      })
      return
    }
    let now_ms = @env.now()
    let (generated_session_id, generated_token) = generated_session_identity(
      "managed", now_ms,
    )
    let result = account_application().admin_create_account(
      token,
      user_id,
      account_management_string(fields, "display_name"),
      account_management_string(fields, "account_kind"),
      account_management_string(fields, "tenant_id").to_lower(),
      account_management_string(fields, "tenant_name"),
      generated_session_id,
      generated_token,
      now_ms~,
    ) catch {
      error => {
        send_json(conn, 409, {
          "ok": false,
          "error": "admin_account_creation_failed",
          "message": "\{error}",
        })
        return
      }
    }
    send_json(conn, 201, {
      "ok": true,
      "session_token": result.opaque_token,
      "account": @account_system.account_context_projection(result.context),
    })
    return
  }
  if path == @town_contract.miniapp_snapshot_path() {
    if !(request.meth is @http.Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    send_json(
      conn,
      200,
      @town_projection.default_town_projection().miniapp_snapshot(),
    )
    return
  }
  if path == @town_contract.miniapp_book_registration_path() {
    if !(request.meth is @http.Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    send_json(conn, 200, {
      "ok": true,
      "schema": "moontown.miniapp.book-catalog.v1",
      "books": miniapp_installed_book_catalog().to_json(),
    })
    return
  }
  let supervisor = @supervisor_setup.default_supervisor_setup_application()
  let actor_user_id = account_context.user_id
  if path == @town_contract.miniapp_supervisor_path() ||
    path == @town_contract.miniapp_supervisor_readiness_path() {
    if !(request.meth is @http.Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.UsePersonalAgent,
        conn,
      ) {
      return
    }
    send_json(conn, 200, supervisor.query_profile(actor_user_id))
    return
  }
  if path == @town_contract.miniapp_supervisor_draft_path() {
    if !require_json_put(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.UsePersonalAgent,
        conn,
      ) {
      return
    }
    let result = supervisor.save_profile_draft(
      actor_user_id,
      bind_miniapp_supervisor_draft(
        @supervisor_setup.parse_supervisor_profile_draft(body.read_all().text()),
        miniapp_installed_book_catalog(),
      ),
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  if path == @town_contract.miniapp_supervisor_activation_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.UsePersonalAgent,
        conn,
      ) {
      return
    }
    if !profile_binding_is_installed(
        supervisor.query_profile(actor_user_id),
        miniapp_installed_book_catalog(),
      ) {
      send_json(conn, 409, {
        "ok": false,
        "error": "the bound MoonBook is no longer installed",
      })
      return
    }
    let result = supervisor.activate_profile(
      actor_user_id,
      @supervisor_setup.parse_supervisor_activation_draft(
        body.read_all().text(),
      ),
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 202, result)
    return
  }
  if path == @town_contract.miniapp_run_steer_path() ||
    path == @town_contract.miniapp_run_delegate_path() ||
    path == @town_contract.miniapp_child_run_steer_path() ||
    path == @town_contract.miniapp_supervisor_wake_path() ||
    path == @town_contract.miniapp_supervisor_stop_path() ||
    path == @town_contract.miniapp_supervisor_resume_path() ||
    path == @town_contract.miniapp_message_path() ||
    path == @town_contract.miniapp_run_cancel_path() ||
    path == @town_contract.miniapp_run_retry_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.UsePersonalAgent,
        conn,
      ) {
      return
    }
    let request_body = body.read_all().text()
    let result = try {
      if path == @town_contract.miniapp_message_path() {
        supervisor.request_message(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_run_delegate_path() {
        supervisor.request_run_delegate(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_child_run_steer_path() {
        supervisor.request_child_run_steer(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_supervisor_wake_path() {
        supervisor.request_supervisor_wake(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_supervisor_stop_path() {
        supervisor.request_supervisor_stop(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_supervisor_resume_path() {
        supervisor.request_supervisor_resume(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_run_cancel_path() {
        supervisor.request_run_cancel(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else if path == @town_contract.miniapp_run_retry_path() {
        supervisor.request_run_retry(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      } else {
        supervisor.request_run_steer(
          actor_user_id,
          request_body,
          now_ms=@env.now(),
        )
      }
    } catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 202, result)
    return
  }
  if review_decision_route(path) {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.PublishTownContent,
        conn,
      ) {
      return
    }
    let result = supervisor.request_bookkeeper_review(
      actor_user_id,
      body.read_all().text(),
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 202, result)
    return
  }
  if path == @town_contract.miniapp_runtime_outbox_path() {
    if !(request.meth is @http.Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManageSystemHealth,
        conn,
      ) {
      return
    }
    send_json(conn, 200, supervisor.runtime_handoffs())
    return
  }
  if path == @town_contract.miniapp_runtime_observation_reconcile_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManageSystemHealth,
        conn,
      ) {
      return
    }
    let result = supervisor.reconcile_runtime_observation(
      miniapp_transport_id(request),
      body.read_all().text(),
      now_ms=@env.now(),
    ) catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    ignore(
      @marketplace_runtime_bridge.sync_action_lineage(
        @storage.moontown_product_state_dir() + "/marketplace/state.json",
        supervisor,
        now_ms=@env.now(),
      ) catch {
        _ => Json::null()
      },
    )
    send_json(conn, 200, result)
    return
  }
  if path == @town_contract.miniapp_runtime_outbox_claim_path() ||
    path == @town_contract.miniapp_runtime_outbox_reconcile_path() ||
    path == @town_contract.miniapp_runtime_outbox_release_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManageSystemHealth,
        conn,
      ) {
      return
    }
    let request_body = body.read_all().text()
    let kind = handoff_kind(request_body)
    let transport_id = miniapp_transport_id(request)
    let result = try {
      if path == @town_contract.miniapp_runtime_outbox_release_path() {
        supervisor.release_runtime_handoff(transport_id, request_body)
      } else if path == @town_contract.miniapp_runtime_outbox_claim_path() {
        if kind == "activation" {
          supervisor.claim_activation_handoff(transport_id, request_body)
        } else if kind == "execution" {
          supervisor.claim_execution_handoff(transport_id, request_body)
        } else {
          fail("runtime handoff kind must be activation or execution")
        }
      } else if kind == "activation" {
        supervisor.reconcile_activation_handoff(transport_id, request_body)
      } else if kind == "execution" {
        supervisor.reconcile_execution_handoff(transport_id, request_body)
      } else {
        fail("runtime handoff kind must be activation or execution")
      }
    } catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    if path == @town_contract.miniapp_runtime_outbox_reconcile_path() &&
      kind == "execution" {
      ignore(
        @marketplace_runtime_bridge.sync_execution_receipt(
          @storage.moontown_product_state_dir() + "/marketplace/state.json",
          request_body,
          result,
          now_ms=@env.now(),
        ) catch {
          _ => Json::null()
        },
      )
    }
    send_json(conn, 200, result)
    return
  }
  if path == @town_contract.miniapp_bookkeeper_outbox_path() {
    if !(request.meth is @http.Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManageSystemHealth,
        conn,
      ) {
      return
    }
    send_json(conn, 200, supervisor.bookkeeper_outbox())
    return
  }
  if path == @town_contract.miniapp_bookkeeper_outbox_claim_path() ||
    path == @town_contract.miniapp_bookkeeper_outbox_reconcile_path() ||
    path == @town_contract.miniapp_bookkeeper_outbox_release_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManageSystemHealth,
        conn,
      ) {
      return
    }
    let request_body = body.read_all().text()
    let transport_id = miniapp_transport_id(request)
    let result = try {
      if path == @town_contract.miniapp_bookkeeper_outbox_release_path() {
        supervisor.release_bookkeeper_review(transport_id, request_body)
      } else if path == @town_contract.miniapp_bookkeeper_outbox_claim_path() {
        supervisor.claim_bookkeeper_review(transport_id, request_body)
      } else {
        supervisor.reconcile_bookkeeper_review(transport_id, request_body)
      }
    } catch {
      error => {
        send_json(conn, 409, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  if path == @town_contract.miniapp_standing_watch_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManagePersonalWorkspace,
        conn,
      ) {
      return
    }
    let application = @town_application.default_request_application(
      operator_policy_path(),
    )
    let result = application.submit_standing_watch(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  if path == @town_contract.miniapp_evidence_book_path() {
    if !require_json_write(request, conn) {
      return
    }
    if !require_account_entitlement(
        account_context,
        @account_system.ManagePersonalWorkspace,
        conn,
      ) {
      return
    }
    let application = @town_application.default_request_application(
      operator_policy_path(),
    )
    let result = application.queue_evidence_book(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  send_json(conn, 404, { "ok": false, "error": "not found" })
}

///|
async fn main {
  let bind = miniapp_bind()
  let plan = configured_account_plan()
  let roles = configured_platform_roles()
  if session_token().is_empty() &&
    (!loopback_bind(bind) || privileged_bootstrap_configured(plan, roles)) {
    fail(
      "MOONTOWN_MINIAPP_SESSION_TOKEN is required for non-loopback or privileged bootstrap access",
    )
  }
  let server = @http.Server(@socket.Addr::parse(bind), reuse_addr=true)
  println(
    "MoonTown mini-app adapter listening at http://\{bind}; suite=\{@storage.moontown_active_workspace_root()}",
  )
  server.run_forever(handle_request, max_connections=32)
}
