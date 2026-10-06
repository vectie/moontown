///|
/// Called only after public_access_gate. This adapter neither constructs the
/// supervisor application nor creates or normalizes the existing Book catalog.
async fn handle_imported_output_api(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Unit {
  let verb = match request.meth {
    Get => "GET"
    Head => "HEAD"
    _ => "OTHER"
  }
  let reply = @imported_outputs.respond(
    verb,
    request.path,
    @moonbook.default_catalog_path(),
    books_root(),
  )
  conn.send_response(
    reply.status,
    if reply.status < 400 {
      "OK"
    } else {
      "Error"
    },
    extra_headers=reply.headers,
  )
  if !reply.body.is_empty() {
    conn.write(reply.body)
  }
  conn.end_response()
}
