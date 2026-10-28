///|
async fn handle_account_read(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  let path = request_path(request)
  guard path == "/account/self.json" || path == "/secret-compute-room.json" else {
    return false
  }
  if env_value("MOONTOWN_PUBLIC_HOST") is Some(_) &&
    !public_service_host(request_header(request, "host")) {
    send_json(conn, 403, { "error": "unexpected host" })
    return true
  }
  if request.meth != Get {
    send_json(conn, 405, { "error": "GET required" })
    return true
  }
  let cookie = request_header(request, "cookie")
  if path == "/secret-compute-room.json" {
    send_json(
      conn,
      200,
      @account_compute.read(
        cookie,
        request_header(request, "x-lunanexa-organization"),
      ),
    )
  } else {
    let result : Json = match @account_identity.resolve(cookie) {
      Disabled => { "state": "disabled" }
      SignedOut => { "state": "sign-in-required" }
      Unavailable => { "state": "unavailable" }
      Authenticated(session) =>
        {
          "state": "bound",
          "account": @account_system.account_context_projection(
            session.context(),
          ),
        }
    }
    send_json(conn, 200, result)
  }
  true
}
